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

@react.component
let make = () => {
  let textualEditions = Store.store->Store.MobileClient.use(state => state.textualEditions)
  let setTextualEditions = Store.store->Store.MobileClient.use(state => {
    state.setTextualEditions
  })
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
    <IonContent>
      <IonList>
        <IonListHeader> {"Available Modules"->React.string} </IonListHeader>
        <IonReorderGroup disabled={false} onIonItemReorder={handleReorder}>
          {textualEditions
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
