%%raw(`import './ParallelReader.css';`)

let baseUrl = "https://dev.parabible.com/api/v2"

let apiEndpoint = baseUrl ++ "/text"

let getUrl = (reference: string, editionsString: string) =>
  `${apiEndpoint}?reference=${reference}&modules=${editionsString}`

let textualEditionsAsString = (textualEditions: array<State.textualEdition>) =>
  textualEditions->Array.map(m => m.abbreviation)->Array.join(",")

let getChapterData = async (
  reference: Books.reference,
  textualEditionsToDisplay: array<State.textualEdition>,
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
    ~textualEditions: array<State.textualEdition>,
    ~chapterData: array<array<option<TextObject.textObject>>>,
  ) => {
    let reference = Store.store->Store.MobileClient.use(state => state.reference)
    textualEditions->Array.length === 0
      ? <div>
          {`No textual editions are enabled for ${reference.book} ${reference.chapter}`->React.string}
        </div>
      : <table className="verse-table">
          <thead>
            <tr>
              {textualEditions
              ->Array.map(t => {
                <td
                  style={{
                    textAlign: "center",
                    fontWeight: "bold",
                    width: (100 / Array.length(textualEditions))->Int.toString ++ "%",
                  }}
                  className="verseText"
                  key={t.id->Int.toString}>
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
let make = (~contentRef: React.ref<RescriptCore.Nullable.t<Dom.element>>) => {
  let currentlyLoadedRequestId = React.useRef(0)
  let maxRequestId = React.useRef(0)
  let (chapterData, setChapterData) = React.useState(_ => [])
  let setReference = Store.store->Store.MobileClient.use(state => state.setReference)
  let targetReference = Store.store->Store.MobileClient.use(state => state.targetReference)
  let setChapterLoadingState =
    Store.store->Store.MobileClient.use(state => state.setChapterLoadingState)
  let textualEditions = Store.store->Store.MobileClient.use(state => state.textualEditions)
  let enabledTextualEditions = textualEditions->Array.filter(m => m.visible)
  let setTargetReference = Store.store->Store.MobileClient.use(state => state.setTargetReference)
  let (textualEditionsToDisplay, setTextualEditionsToDisplay) = React.useState(_ => [])

  // useEffect can't take arrays and it doesn't correctly memoize objects, so serialize deps
  let serializedReference = `${targetReference.book} ${targetReference.chapter}`
  let serializedTextualEditionsToDisplay =
    enabledTextualEditions->Array.map(m => string_of_int(m.id))->Array.join(",")

  React.useEffect2(() => {
    maxRequestId.current = maxRequestId.current + 1
    let requestId = maxRequestId.current
    if enabledTextualEditions->Js.Array.length > 0 {
      setChapterLoadingState(Loading)
      ignore(
        getChapterData(targetReference, enabledTextualEditions)
        ->Promise.then(data => {
          switch data {
          | Belt.Result.Error(e) => {
              e->Console.error
              setChapterLoadingState(Error)
            }
          | Belt.Result.Ok(data) =>
            // if data is older than currently loaded data, don't update the state
            if requestId > currentlyLoadedRequestId.current {
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
                  row =>
                    row->Array.filterWithIndex((_, i) => columnHasData[i]->Option.getOr(false)),
                )
              setChapterData(_ => newChapterData)
              setChapterLoadingState(Ready)
              setReference(targetReference)
              currentlyLoadedRequestId.current = requestId

              // scroll to top
              switch contentRef.current {
              | Value(node) => node->WindowBindings.scrollToPoint(~x=0, ~y=0, ~duration=300)
              | Null | Undefined => "Cannot scroll: ref.current is None"->Console.error
              }
            }
          }
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          setChapterLoadingState(Error)
          Promise.resolve()
        }),
      )
    }
    None
  }, (serializedReference, serializedTextualEditionsToDisplay))

  let goToAdjacentChapter = forward => {
    let newReference = Books.getAdjacentChapter(targetReference, forward)
    setTargetReference(newReference)
  }

  <div className="parallel-reader">
    <div className="content">
      <VerseTable chapterData={chapterData} textualEditions={textualEditionsToDisplay} />
    </div>
    <button onClick={_ => goToAdjacentChapter(true)} className="chapter-button">
      {"Next Chapter"->React.string}
    </button>
  </div>
}
