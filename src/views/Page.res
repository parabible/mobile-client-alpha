// module IonButton = IonicBindings.IonButton
open IonicBindings

@react.component
let make = () => {
  let ref = React.useRef(Nullable.null)
  // let state = React.useContext(State.context)
  let reference = Zustand.store->Zustand.SomeStore.use(state => {
    let r: Zustand.reference = {
      book: state.reference.book,
      chapter: state.reference.chapter,
    }
    r
  })
  // let setReference = Zustand.store->Zustand.SomeStore.use(state => state.setReference)

  <IonPage>
    <IonHeader>
      <IonToolbar>
        <IonButtons slot="start">
          <IonButton
            shape=#round onClick={() => IonicFunctions.menuController.\"open"("book-selector")}>
            <IonIcon slot="icon-only" icon={IonIcons.library} />
          </IonButton>
        </IonButtons>
        <IonTitle> {`${Books.getBookAbbreviation(reference.book)} ${reference.chapter}`->React.string} </IonTitle>
        <IonButtons slot="end">
          <IonButton
            shape=#round onClick={() => IonicFunctions.menuController.\"open"("textualEditions")}>
            <IonIcon slot="icon-only" icon={IonIcons.apps} />
          </IonButton>
          // <IonButton
          //   shape=#round onClick={() => IonicFunctions.menuController.\"open"("settings")}>
          //   <IonIcon slot="icon-only" icon={IonIcons.settings} />
          // </IonButton>
        </IonButtons>
      </IonToolbar>
    </IonHeader>
    <IonContent ref={ReactDOM.Ref.domRef(ref)}>
      <ParallelReader reference={reference} contentRef={ref} />
      <SearchResults />
      <WordInfo />
    </IonContent>
  </IonPage>
}
