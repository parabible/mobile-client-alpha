%%raw(`import './ParallelReader.css';`)

@send
external scrollToPoint: (Dom.element, ~x: int, ~y: int, ~duration: int) => unit = "scrollToPoint"

let baseUrl = "https://dev.parabible.com/api/v2"

let apiEndpoint = baseUrl ++ "/text"

let getUrl = (reference: string, editionsString: string) =>
  `${apiEndpoint}?reference=${reference}&modules=${editionsString}`

let textualEditionsAsString = (textualEditions: array<Zustand.textualEdition>) =>
  textualEditions->Array.map(m => m.abbreviation)->Array.join(",")

let getChapterData = async (
  reference: Zustand.reference,
  textualEditionsToDisplay: array<Zustand.textualEdition>,
) => {
  let textualEditionsToDisplayAbbreviations = textualEditionsToDisplay->textualEditionsAsString
  let url = getUrl(`${reference.book} ${reference.chapter}`, textualEditionsToDisplayAbbreviations)
  let response = await Fetch.fetch(url, {method: #GET})
  let json = await response->Fetch.Response.json
  json->Json.decode(TextObject.decodeTextResult)
}

module VerseTable = {
  @react.component
  let make = (
    ~textualEditions: array<Zustand.textualEdition>,
    ~chapterData: array<array<option<TextObject.textObject>>>,
  ) => {
    let reference = Zustand.store->Zustand.SomeStore.use(state => state.reference)
    textualEditions->Array.length === 0
      ? <div>
          {`No textual editions are enabled for ${reference.book} ${reference.chapter}`->React.string}
        </div>
      : <table>
          <thead>
            <tr>
              {textualEditions
              ->Array.map(t => {
                <td
                  style={{textAlign: "center", fontWeight: "bold"}}
                  className="verseText"
                  key={t.id->Int.toString}
                  width={(100 / Array.length(textualEditions))->Int.toString ++ "%"}>
                  {t.abbreviation->React.string}
                </td>
              })
              ->React.array}
            </tr>
          </thead>
          <tbody>
            {chapterData
            ->Array.mapWithIndex((element, i) => {
              <tr key={i->Int.toString}>
                {element
                ->Array.mapWithIndex((innerElement, j) => {
                  switch (textualEditions[j], innerElement) {
                  | (Some(t), Some(el)) =>
                    <TextObject.VerseCell
                      key={j->Int.toString}
                      style={TextObject.getStyleFor(t.abbreviation)}
                      textObject={el}
                      textualEditionId={t.id}
                      verseNumber={Some(mod(el.rid, 1000))}
                    />
                  | _ => {
                      "Unknown textualEditionId in ParallelReader"->Console.error
                      <td key={j->Int.toString} />
                    }
                  }
                })
                ->React.array}
              </tr>
            })
            ->React.array}
          </tbody>
        </table>
  }
}

@react.component
let make = (
  ~reference: Zustand.reference,
  ~contentRef: React.ref<RescriptCore.Nullable.t<Dom.element>>,
) => {
  let buttonRef = React.useRef(Nullable.null)
  let (chapterData, setChapterData) = React.useState(_ => [])
  let setReference = Zustand.store->Zustand.SomeStore.use(state => state.setReference)
  let textualEditions = Zustand.store->Zustand.SomeStore.use(state => state.textualEditions)
  let enabledTextualEditions = textualEditions->Array.filter(m => m.visible)
  let (textualEditionsToDisplay, setTextualEditionsToDisplay) = React.useState(_ => [])

  // useEffect can't take arrays and it doesn't correctly memoize objects, so serialize deps
  let serializedReference = `${reference.book} ${reference.chapter}`
  let serializedTextualEditionsToDisplay =
    enabledTextualEditions->Array.map(m => string_of_int(m.id))->Array.join(",")

  React.useEffect2(() => {
    serializedReference->Console.log
    enabledTextualEditions->Js.Array.length->Console.log
    if enabledTextualEditions->Js.Array.length > 0 {
      let _ = getChapterData(reference, enabledTextualEditions)->Promise.then(data => {
        switch data {
        | Belt.Result.Error(e) => e->Console.error
        | Belt.Result.Ok(data) => {
            let columnHasData =
              data
              ->Array.at(0)
              ->Option.getOr([])
              ->Array.mapWithIndex(
                (_, i) => {
                  let onlyColumnI = data->Array.map(row => row[i]->Option.getOr(None))
                  onlyColumnI->Array.some(t => Option.isSome(t))
                },
              )
            let newTextualEditionsToDisplay =
              enabledTextualEditions->Array.filterWithIndex(
                (_, i) => columnHasData[i]->Option.getOr(false),
              )
            setTextualEditionsToDisplay(_ => newTextualEditionsToDisplay)
            let newChapterData =
              data->Array.map(
                row => row->Array.filterWithIndex((_, i) => columnHasData[i]->Option.getOr(false)),
              )
            setChapterData(_ => newChapterData)
            // let y = switch buttonRef.current {
            // | Value(node) => {
            //     // top of the button
            //     let rect = node->Webapi.Dom.Element.getBoundingClientRect
            //     rect["height"]
            //     0
            //   }
            // | Null | Undefined => 0
            // }
            // y->Console.log
            // |Value(node) => {
            //   // bottom of the button
            //   let rect = node->Webapi.Dom.Element.getBoundingClientRect->Webapi.Dom.Element.getBoundingClientRect
            //   rect["bottom"]
            // }
            // |Null|Undefined => 0
            let y = 0

            // scroll to top
            switch contentRef.current {
            | Value(node) => node->scrollToPoint(~x=0, ~y, ~duration=300)
            | Null | Undefined => "Cannot scroll: ref.current is None"->Console.error
            }
          }
        }
        Promise.resolve()
      })
    }
    None
  }, (serializedReference, serializedTextualEditionsToDisplay))

  let goToAdjacentChapter = forward => {
    let newReference = Books.getAdjacentChapter(reference, forward)
    setReference(newReference)
  }

  <div>
    <button
      ref={ReactDOM.Ref.domRef(buttonRef)}
      onClick={_ => goToAdjacentChapter(false)}
      className="chapter-button">
      {"Previous Chapter"->React.string}
    </button>
    <VerseTable chapterData={chapterData} textualEditions={textualEditionsToDisplay} />
    <button onClick={_ => goToAdjacentChapter(true)} className="chapter-button">
      {"Next Chapter"->React.string}
    </button>
  </div>
}
