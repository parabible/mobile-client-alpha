open IonicBindings

let baseUrl = "https://dev.parabible.com/api/v2"

let apiEndpoint = baseUrl ++ "/word"

let getUrl = (wordId, textualEditionId) =>
  `${apiEndpoint}?wid=${wordId->Int.toString}&moduleId=${textualEditionId->Int.toString}`

type wordInfoEntry = {
  key: string,
  value: string,
}

type wordInfo = array<wordInfoEntry>

type wordInfoContainer = {data: wordInfo}

let wordInfoDecoder = Json.Decode.object(field => {
  data: field.required(
    "data",
    Json.Decode.array(
      Json.Decode.object(field => {
        key: field.required("key", Json.Decode.string),
        value: field.required("value", Json.Decode.string),
      }),
    ),
  ),
})

let getWordInfo = async (wordId, textualEditionId) => {
  let url = getUrl(wordId, textualEditionId)
  let response = await Fetch.fetch(url, {method: #GET})
  let json = await response->Fetch.Response.json
  json->Json.decode(wordInfoDecoder)
}

@react.component
let make = () => {
  let (currentWordInfo, setCurrentWordInfo) = React.useState(_ => [])
  let selectedWord = Zustand.store->Zustand.SomeStore.use(state => state.selectedWord)
  let showWordInfo = Zustand.store->Zustand.SomeStore.use(state => state.showWordInfo)
  let setShowWordInfo = Zustand.store->Zustand.SomeStore.use(state => {
    state.setShowWordInfo
  })
  let hideWordInfo = () => setShowWordInfo(false)
  let setShowSearchResults = Zustand.store->Zustand.SomeStore.use(state => {
    state.setShowSearchResults
  })
  let setSearchLexeme = Zustand.store->Zustand.SomeStore.use(state => state.setSearchLexeme)
  let doSearch = lexeme => {
    setSearchLexeme(lexeme)
    setShowSearchResults(true)
    // Ionic creates and removes dom elements. If we don't hideWordInfo,
    // the modal only shows beneath the search results.
    hideWordInfo()
  }

  React.useEffect(() => {
    if showWordInfo {
      let _ = getWordInfo(selectedWord.id, selectedWord.moduleId)->Promise.then(data => {
        switch data {
        | Belt.Result.Error(e) => e->Console.error
        | Belt.Result.Ok(result) => setCurrentWordInfo(_ => result.data)
        }
        Promise.resolve()
      })
    }
    None
  }, [showWordInfo])

  let lexeme =
    currentWordInfo
    ->Array.find(wi => wi.key === "lexeme")
    ->Option.map(wi => wi.value)
    ->Option.getOr("")
  let gloss =
    currentWordInfo
    ->Array.find(wi => wi.key === "gloss")
    ->Option.map(wi => wi.value)
    ->Option.getOr("")

  <IonModal
    className="word-info"
    isOpen={showWordInfo}
    initialBreakpoint={0.11}
    breakpoints={[0., 0.11, 1.]}
    onDidDismiss={hideWordInfo}>
    <IonContent className="ion-padding">
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          fontSize: "1.3rem",
          fontFamily: "SBL BibLit",
          padding: "0 1rem 0.8rem",
        }}>
        <b> {lexeme->React.string} </b>
        <b> {gloss->React.string} </b>
        <IonButton shape=#round onClick={() => doSearch(lexeme)}>
          <IonIcon slot="icon-only" icon={IonIcons.search} />
        </IonButton>
      </div>
      <IonList>
        {currentWordInfo
        ->Array.map(wi =>
          <IonItem key={wi.key}>
            <IonLabel>
              <h2> {Features.getFeatureValue(wi.key, wi.value)->React.string} </h2>
              <p> {Features.getFeatureName(wi.key)->React.string} </p>
            </IonLabel>
          </IonItem>
        )
        ->React.array}
      </IonList>
    </IonContent>
  </IonModal>
}
