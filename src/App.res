%%raw(`
import '@ionic/react/css/core.css';
import '@ionic/react/css/normalize.css';
import '@ionic/react/css/structure.css';
import '@ionic/react/css/typography.css';
import '@ionic/react/css/padding.css'
import '@ionic/react/css/float-elements.css';
import '@ionic/react/css/text-alignment.css'
import '@ionic/react/css/text-transformation.css';
import '@ionic/react/css/flex-utils.css';
import '@ionic/react/css/display.css';
import '@ionic/react/css/palettes/dark.class.css';
import './App.css';
`)

open Webapi
open IonicBindings
IonicFunctions.setupIonicReact()

@react.component
let make = () => {
  let textualEditions = Store.store->Store.MobileClient.use(state => state.textualEditions)
  let setTextualEditions = Store.store->Store.MobileClient.use(state => {
    state.setTextualEditions
  })
  let darkMode = Store.store->Store.MobileClient.use(state => state.darkMode)

  React.useEffect0(() => {
    State.refreshTextualEditions(textualEditions, setTextualEditions)
    None
  })

  React.useEffect1(() => {
    let classList =
      Dom.document
      ->Dom.Document.documentElement
      ->Dom.Element.classList
    if darkMode {
      classList->Dom.DomTokenList.add("ion-palette-dark")
    } else {
      classList->Dom.DomTokenList.remove("ion-palette-dark")
    }
    None
  }, [darkMode])

  <IonApp>
    <UrlManager>
      <BookSelectorMenu />
      <TextualEditionsMenu />
      <Page />
    </UrlManager>
  </IonApp>
}
