open IonicBindings

let defaultEnabledTextualEditions = ["BHSA", "NET", "NA1904", "CAFE", "APF"]

let decodeTextualEditions = Json.Decode.object(container =>
  {
    "data": container.required(
      "data",
      Json.Decode.array(
        Json.Decode.object(field =>
          {
            "moduleId": field.required("moduleId", Json.Decode.int),
            "abbreviation": field.required("abbreviation", Json.Decode.string),
          }
        ),
      ),
    ),
  }
)

@react.component
let make = () => {
  let textualEditions = Zustand.store->Zustand.SomeStore.use(state => state.textualEditions)
  let setTextualEditions = Zustand.store->Zustand.SomeStore.use(state => {
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

  React.useEffect0(() => {
    let url = "https://dev.parabible.com/api/v2/module"

    ignore(
      Fetch.fetch(url, {method: #GET})
      ->Promise.then(response => {
        response->Fetch.Response.json
      })
      ->Promise.then(data => {
        let d = data->Json.decode(decodeTextualEditions)
        switch d {
        | Belt.Result.Error(e) => e->Console.error
        | Belt.Result.Ok(d) => {
            let mappedTextualEditions = d["data"]->Array.map(
              m => {
                let t: Zustand.textualEdition = {
                  id: m["moduleId"],
                  abbreviation: m["abbreviation"],
                  visible: defaultEnabledTextualEditions->Array.includes(m["abbreviation"])
                }
                t
              },
            )
            setTextualEditions(mappedTextualEditions)
          }
        }
        Promise.resolve()
      }),
    )
    None
  })

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
                {textualEdition.abbreviation->React.string}
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
