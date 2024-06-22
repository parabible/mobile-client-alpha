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
import './App.css';
`)

open IonicBindings
IonicFunctions.setupIonicReact()

@react.component
let make = () => {
  <IonApp>
    // <State.Provider value={State.initialState}>
    <IonReactRouter>
      <BookSelectorMenu />
      <TextualEditionsMenu />
      <IonRouterOutlet id="main">
        <Route path="/" exact={true}>
          <Redirect to={`/Genesis 1`} />
        </Route>
        <Route path="/:name" exact={true}>
          <Page />
        </Route>
      </IonRouterOutlet>
    </IonReactRouter>
    // </State.Provider>
  </IonApp>
}
