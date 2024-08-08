open IonicBindings

module TextualEditionLabel = {
  @react.component
  let make = (~abbreviation: string) => {
    let d = State.temporaryTextualEditionData->Array.find(te => te.abbreviation == abbreviation)

    switch d {
    | None => <IonLabel> {abbreviation->React.string} </IonLabel>
    | Some(d) =>
      <>
        <IonLabel>
          {abbreviation->React.string}
          {(" (" ++ d.language ++ ")")->React.string}
        </IonLabel>
        <IonNote> {d.fullname->React.string} </IonNote>
      </>
    }
  }
}

type textualEditionDisplayOptionsList = {
  id: string,
  option: Store.textualEditionDisplayOptions,
  description: string,
}
let defaultTextualLanguageOption = {
  id: "all",
  option: All,
  description: "All",
}
let textualEditionLanguageOptions = [
  defaultTextualLanguageOption,
  {
    id: "english",
    option: English,
    description: "English",
  },
  {
    id: "source-texts",
    option: SourceTexts,
    description: "Source Texts",
  },
]

@react.component
let make = () => {
  let reference = Store.store->Store.MobileClient.use(state => state.reference)
  let textualEditions = Store.store->Store.MobileClient.use(state => state.textualEditions)
  let setTextualEditions = Store.store->Store.MobileClient.use(state => {
    state.setTextualEditions
  })
  let (filterToVisible, setFilterToVisible) = React.useState(_ => false)
  let (filterToCurrentCorpus, setFilterToCurrentCorpus) = React.useState(_ => true)
  let (textualEditionLanguage, setTextualEditionLanguage) = React.useState(_ => Store.English)
  let actualTextualEditionDisplayOption =
    textualEditionLanguageOptions
    ->Array.find(v => v.option == textualEditionLanguage)
    ->Option.getOr(defaultTextualLanguageOption)

  let handleDisplayOptionsChange = (newValue: string) => {
    let option = textualEditionLanguageOptions->Array.find(v => v.id == newValue)
    let newValue = switch option {
    | None => Store.All
    | Some(option) => option.option
    }
    setTextualEditionLanguage(_ => newValue)
  }

  let toggleTextualEdition = id => {
    let newTextualEditions = textualEditions->Array.map(m => {
      if m.id == id {
        {...m, visible: !m.visible}
      } else {
        m
      }
    })
    setTextualEditions(newTextualEditions)
  }

  let handleReorder = (event: IonReorderGroup.event) => {
    let from = event.detail.from
    let to = event.detail.to

    let item = Array.at(textualEditions, from)
    switch item {
    | None => "Item not found"->Console.error
    | Some(item) => {
        let newTextualEditions = Array.copy(textualEditions)
        Array.splice(newTextualEditions, ~start=from, ~remove=1, ~insert=[])
        Array.splice(newTextualEditions, ~start=to, ~remove=0, ~insert=[item])
        setTextualEditions(newTextualEditions)
      }
    }
    event.detail.complete()
    ()
  }

  <IonMenu menuId="textualEditions" side="end" contentId="main" \"type"="overlay">
    <IonContent className="ion-padding">
      <h1 className="text-xl"> {"Textual Editions"->React.string} </h1>
      <IonList>
        <IonItem>
          <IonToggle
            checked={filterToVisible} onIonChange={x => setFilterToVisible(_ => x.detail.checked)}>
            {"Only Show Visible"->React.string}
          </IonToggle>
        </IonItem>
        <IonItem>
          <IonToggle
            checked={filterToCurrentCorpus}
            onIonChange={x => setFilterToCurrentCorpus(_ => x.detail.checked)}>
            {"Only Show Relevant"->React.string}
          </IonToggle>
        </IonItem>
        <IonItem>
          <IonSelect
            label="Languages to Show"
            value={actualTextualEditionDisplayOption.id}
            onIonChange={x => x.detail.value->handleDisplayOptionsChange}>
            {textualEditionLanguageOptions
            ->Array.map(v =>
              <IonSelectOption key={v.id} value={v.id}>
                {v.description->React.string}
              </IonSelectOption>
            )
            ->React.array}
          </IonSelect>
        </IonItem>
      </IonList>
      <h2 className="text-lg mt-4"> {"Reorder Textual Editions"->React.string} </h2>
      <IonList>
        <IonReorderGroup disabled={false} onIonItemReorder={handleReorder}>
          {textualEditions
          ->Array.filter(te => !filterToVisible || te.visible)
          ->Array.filter(te =>
            switch filterToCurrentCorpus {
            | true => {
                let d =
                  State.temporaryTextualEditionData->Array.find(t =>
                    t.abbreviation == te.abbreviation
                  )
                let corpus = reference->ReferenceParser.getCorpusFromReference
                switch (corpus, d) {
                | (Some(corpus), Some(d)) => d.corpora->Array.includes((corpus :> State.corpora))
                | _ => false
                }
              }
            | false => true
            }
          )
          ->Array.filter(te => {
            let d =
              State.temporaryTextualEditionData->Array.find(t => t.abbreviation == te.abbreviation)
            switch actualTextualEditionDisplayOption.option {
            | All => true
            | English => d->Option.map(d => d.language == "English")->Option.getOr(false)
            | SourceTexts => d->Option.map(d => d.source_text)->Option.getOr(false)
            }
          })
          ->Array.map(textualEdition =>
            <IonItem key={textualEdition.abbreviation}>
              <IonCheckbox
                labelPlacement=#end
                justify="start"
                checked={textualEdition.visible}
                onIonChange={_ => toggleTextualEdition(textualEdition.id)}>
                <TextualEditionLabel abbreviation={textualEdition.abbreviation} />
              </IonCheckbox>
              <IonReorder slot="end" />
            </IonItem>
          )
          ->React.array}
        </IonReorderGroup>
      </IonList>
    </IonContent>
  </IonMenu>
}
