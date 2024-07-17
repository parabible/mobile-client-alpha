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

let wordInfoToDataPoint: wordInfoEntry => State.searchTermDataPoint = wi => {
  key: wi.key,
  value: wi.value,
}

type mode =
  | View
  | CreateSearchTerm

module WordInfoItem = {
  @react.component
  let make = (~heading, ~subheading) => {
    <IonLabel>
      <h2> {heading->React.string} </h2>
      <p> {subheading->React.string} </p>
    </IonLabel>
  }
}

module CheckableWordInfoItem = {
  let onCheckboxChange = e => {
    let target = e->JsxEvent.Form.target
    (target["checked"]: bool)
  }
  @react.component
  let make = (~heading, ~subheading, ~isChecked, ~onCheck) => {
    <IonCheckbox checked={isChecked} onIonChange={e => onCheck(onCheckboxChange(e))}>
      <WordInfoItem heading subheading />
    </IonCheckbox>
  }
}

@react.component
let make = () => {
  // let (currentWordInfo, setCurrentWordInfo) = React.useState(_ => [])
  // let (checkedDataPoints, setCheckedDataPoints) = React.useState(_ => [])
  let (presentToast, dismissToast) = IonicFunctions.useIonToast()
  // let (currentMode, setCurrentMode) = React.useState(_ => View)
  let selectedWord = Store.store->Store.MobileClient.use(state => state.selectedWord)
  let showWordInfo = Store.store->Store.MobileClient.use(state => state.showWordInfo)
  // let setShowWordInfo = Store.store->Store.MobileClient.use(state => {
  //   state.setShowWordInfo
  // })
  // let hideWordInfo = () => {
  //   setCurrentMode(_ => View)
  //   setShowWordInfo(false)
  // }
  // let setShowSearchResults = Store.store->Store.MobileClient.use(state => {
  //   state.setShowSearchResults
  // })
  let addSearchTerm = Store.store->Store.MobileClient.use(state => state.addSearchTerm)

  // let lexeme =
  //   currentWordInfo
  //   ->Array.find(wi => wi.key === "lexeme")
  //   ->Option.map(wi => wi.value)
  //   ->Option.getOr("")
  // let gloss =
  //   currentWordInfo
  //   ->Array.find(wi => wi.key === "gloss")
  //   ->Option.map(wi => wi.value)
  //   ->Option.getOr("")
  // let addSearch = () => {
  //   let searchTerm: State.searchTerm = switch currentMode {
  //   | View => {
  //       uuid: WindowBindings.randomUUID(),
  //       inverted: false,
  //       data: [
  //         {
  //           key: "lexeme",
  //           value: lexeme,
  //         },
  //       ],
  //     }
  //   | CreateSearchTerm => {
  //       uuid: WindowBindings.randomUUID(),
  //       inverted: false,
  //       data: currentWordInfo
  //       ->Array.filterWithIndex((_, i) => checkedDataPoints->Array.get(i)->Option.getOr(false))
  //       ->Array.map(wordInfoToDataPoint),
  //     }
  //   }
  //   addSearchTerm(searchTerm)
  //   setShowSearchResults(true)
  //   hideWordInfo()
  // }

  React.useEffect3(() => {
    if showWordInfo {
      ignore(
        getWordInfo(selectedWord.id, selectedWord.moduleId)->Promise.then(async data => {
          switch data {
          | Belt.Result.Error(e) => e->Console.error
          | Belt.Result.Ok(result) => {
              // setCheckedDataPoints(_ => result.data->Array.map(_ => false))
              // setCurrentWordInfo(_ => result.data)
              let lexeme =
                result.data
                ->Array.find(wi => wi.key === "lexeme")
                ->Option.map(wi => wi.value)
                ->Option.getOr("")
              let gloss =
                result.data
                ->Array.find(wi => wi.key === "gloss")
                ->Option.map(wi => wi.value)
                ->Option.getOr("")
              let _ = await dismissToast()
              presentToast({
                message: lexeme ++ " · " ++ gloss,
                duration: 3000,
                swipeGesture: #vertical,
                buttons: [
                  // {icon: IonIcons.ellipsisVertical},
                  {
                    icon: IonIcons.search,
                    handler: _ => addSearchTerm({
                      uuid: WindowBindings.randomUUID(),
                      inverted: false,
                      data: [
                        {
                          key: "lexeme",
                          value: lexeme,
                        },
                      ],
                    }),
                  },
                  {icon: IonIcons.close, role: "cancel"},
                ],
              })
            }
          }
          Promise.resolve()
        }),
      )
    }
    None
  }, (showWordInfo, selectedWord.id, selectedWord.moduleId))

  <> </>
  // <IonModal
  //   className="word-info"
  //   isOpen={showWordInfo}
  //   initialBreakpoint={0.11}
  //   backdropBreakpoint={0.3}
  //   breakpoints={[0., 0.11, 1.]}
  //   onDidDismiss={hideWordInfo}>
  //   <IonContent className="ion-padding">
  //     <div
  //       style={{
  //         display: "flex",
  //         justifyContent: "space-between",
  //         alignItems: "center",
  //         fontSize: "1.3rem",
  //         fontFamily: "SBL BibLit",
  //         padding: "0 1rem 0.8rem",
  //       }}>
  //       <b> {lexeme->React.string} </b>
  //       <b> {gloss->React.string} </b>
  //       <IonButton shape=#round onClick={addSearch}>
  //         <IonIcon slot="icon-only" icon={IonIcons.search} />
  //       </IonButton>
  //     </div>
  //     <IonList>
  //       {currentWordInfo
  //       ->Array.mapWithIndex((wi, i) =>
  //         <IonItem key={wi.key}>
  //           {
  //             let heading = Features.getFeatureValue(wi.key, wi.value)
  //             let subheading = Features.getFeatureName(wi.key)
  //             switch currentMode {
  //             | View => <WordInfoItem heading subheading />
  //             | CreateSearchTerm =>
  //               <CheckableWordInfoItem
  //                 heading
  //                 subheading
  //                 isChecked={checkedDataPoints->Array.get(i)->Option.getOr(false)}
  //                 onCheck={newVal => {
  //                   setCheckedDataPoints(oldDataPoints => {
  //                     oldDataPoints->Array.mapWithIndex((val, j) => i === j ? newVal : val)
  //                   })
  //                 }}
  //               />
  //             }
  //           }
  //         </IonItem>
  //       )
  //       ->React.array}
  //     </IonList>
  //     {switch currentMode {
  //     | View =>
  //       <IonButton expand={#full} onClick={_ => setCurrentMode(_ => CreateSearchTerm)}>
  //         {"Create Custom Search Term"->React.string}
  //       </IonButton>
  //     | CreateSearchTerm =>
  //       <div style={{display: "grid", grid: "auto-flow / 1fr 1fr"}}>
  //         <IonButton expand={#full} onClick={addSearch}> {"Search"->React.string} </IonButton>
  //         <IonButton expand={#full} color={#light} onClick={_ => setCurrentMode(_ => View)}>
  //           {"Cancel"->React.string}
  //         </IonButton>
  //       </div>
  //     }}
  //   </IonContent>
  // </IonModal>
}
