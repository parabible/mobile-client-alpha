open IonicBindings

type teMatch = array<TextObject.textObject>

type resultRow = array<teMatch>

type matchingWord = {textualEditionId: int, wid: int}

type warmWord = {textualEditionId: int, wids: array<int>}

type termSearchResult = {
  count: int,
  matchingText: array<resultRow>,
  matchingWords: array<matchingWord>,
  warmWords: array<warmWord>,
}

let decodeMatchingWords = Json.Decode.array(
  Json.Decode.object(field => {
    textualEditionId: field.required("moduleId", Json.Decode.int),
    wid: field.required("wid", Json.Decode.int),
  }),
)

let decodeWarmWords = Json.Decode.array(
  Json.Decode.object(field => {
    textualEditionId: field.required("moduleId", Json.Decode.int),
    wids: field.required("wids", Json.Decode.array(Json.Decode.int)),
  }),
)

let decodeTermSearchResult = Json.Decode.object(field => {
  count: field.required("count", Json.Decode.int),
  matchingText: field.required(
    "matchingText",
    Json.Decode.array(Json.Decode.array(Json.Decode.array(TextObject.decodeTextObject))),
  ),
  matchingWords: field.required("matchingWords", decodeMatchingWords),
  warmWords: field.required("warmWords", decodeWarmWords),
})

let getUrl = (searchLexeme, textualEditionAbbreviations) =>
  `https://dev.parabible.com/api/v2/termSearch?t.0.data.lexeme=${searchLexeme}&modules=${textualEditionAbbreviations}&treeNodeType=verse&pageNumber=0&pageSize=10`

let getSearchResults = async (searchLexeme, textualEditionAbbreviations) => {
  let url = getUrl(searchLexeme, textualEditionAbbreviations)
  let response = await Fetch.fetch(url, {method: #GET})
  let json = await response->Fetch.Response.json
  json->Json.decode(decodeTermSearchResult)
}

module OrderedResults = {
  @react.component
  let make = (~results, ~visibleModules: array<Zustand.textualEdition>) => {
    let getTextualEditionByIndex = index => visibleModules->Array.get(index)
    <table>
      <thead>
        <tr>
          {visibleModules
          ->Array.map(t => {
            <td
              style={{textAlign: "center", fontWeight: "bold"}}
              key={t.id->Int.toString}
              width={(100 / Array.length(visibleModules))->Int.toString ++ "%"}>
              {t.abbreviation->React.string}
            </td>
          })
          ->React.array}
        </tr>
      </thead>
      <tbody>
        {results
        ->Array.mapWithIndex((row, ri) =>
          <tr key={ri->Int.toString}>
            {row
            ->Array.mapWithIndex((textualEditionResult, ti) => {
              switch ti->getTextualEditionByIndex {
              | None => "Something went wrong identifying this textualEdition"->React.string
              | Some(t) =>
                <td
                  key={ti->Int.toString}
                  className="verseText"
                  style={TextObject.getStyleFor(t.abbreviation)}>
                  {textualEditionResult
                  ->Array.mapWithIndex(
                    (v, vi) =>
                      <TextObject.VerseSpan
                        key={vi->Int.toString}
                        textObject={v}
                        textualEditionId={t.id}
                        verseNumber={Some(mod(v.rid, 1000))}
                      />,
                  )
                  ->React.array}
                </td>
              }
            })
            ->React.array}
          </tr>
        )
        ->React.array}
      </tbody>
    </table>
  }
}

@react.component
let make = () => {
  let (matchingText, setMatchingText) = React.useState(_ => None)
  let searchLexeme = Zustand.store->Zustand.SomeStore.use(state => state.searchLexeme)
  let textualEditions = Zustand.store->Zustand.SomeStore.use(state => state.textualEditions)
  let enabledTextualEditions = textualEditions->Array.filter(m => m.visible)
  let textualEditionAbbreviations =
    enabledTextualEditions
    ->Array.map(m => m.abbreviation)
    ->Array.join(",")
  let (textualEditionsToDisplay, setTextualEditionsToDisplay) = React.useState(_ => [])
  let showSearchResults = Zustand.store->Zustand.SomeStore.use(state => state.showSearchResults)
  let setShowSearchResults =
    Zustand.store->Zustand.SomeStore.use(state => state.setShowSearchResults)
  let hideSearchResults = () => setShowSearchResults(false)

  React.useEffect2(() => {
    if searchLexeme != "" && textualEditionAbbreviations != "" {
      let _ = getSearchResults(searchLexeme, textualEditionAbbreviations)->Promise.then(results => {
        switch results {
        | Belt.Result.Error(e) => {
            e->Console.error
            setMatchingText(_ => None)
          }
        | Belt.Result.Ok(results) => {
            let columnHasData =
              results.matchingText
              ->Array.at(0)
              ->Option.getOr([])
              ->Array.mapWithIndex(
                (_, i) => {
                  results.matchingText->Array.some(
                    row => row->Array.get(i)->Option.getOr([])->Array.length > 0,
                  )
                },
              )
            results.matchingText->Array.length->Console.log
            columnHasData->Console.log
            let pluckColumns = (row, columns) =>
              row->Array.filterWithIndex((_, i) => columns[i]->Option.getOr(false))
            let newTextualEditionsToDisplay = pluckColumns(enabledTextualEditions, columnHasData)
            newTextualEditionsToDisplay->Console.log
            // enabledTextualEditions->Array.filterWithIndex(
            //   (_, i) => columnHasData[i]->Option.getOr(false),
            // )
            setTextualEditionsToDisplay(_ => newTextualEditionsToDisplay)
            setMatchingText(
              _ => Some(results.matchingText->Array.map(row => row->pluckColumns(columnHasData))),
            )
          }
        }
        Promise.resolve()
      })
    }
    None
  }, (searchLexeme, textualEditionAbbreviations))

  <IonModal isOpen={showSearchResults} onDidDismiss={hideSearchResults}>
    <IonHeader>
      <IonToolbar>
        <IonTitle> {"Search Results"->React.string} </IonTitle>
        <IonButtons slot="end">
          <IonButton shape="round" onClick={() => hideSearchResults()}>
            <IonIcon slot="icon-only" icon={IonIcons.close} />
          </IonButton>
        </IonButtons>
      </IonToolbar>
    </IonHeader>
    <IonContent className="ion-padding" scrollX={true}>
      {switch matchingText {
      | None => "No results"->React.string
      | Some(matchingText) =>
        <OrderedResults results={matchingText} visibleModules={textualEditionsToDisplay} />
      }}
    </IonContent>
  </IonModal>
}
