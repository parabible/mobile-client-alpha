// module IonButton = IonicBindings.IonButton
open IonicBindings

@react.component
let make = () => {
  let ref = React.useRef(Nullable.null)
  // let state = React.useContext(State.context)
  let reference = Store.store->Store.MobileClient.use(state => {
    let r: State.reference = {
      book: state.reference.book,
      chapter: state.reference.chapter,
    }
    r
  })
  let setReference = Store.store->Store.MobileClient.use(state => state.setReference)
  let goToAdjacentChapter = forward => {
    let newReference = Books.getAdjacentChapter(reference, forward)
    setReference(newReference)
  }

  <IonPage>
    <IonHeader>
      <IonToolbar>
        <IonButtons slot="start">
          <IonButton
            shape=#round onClick={() => IonicFunctions.menuController.\"open"("book-selector")}>
            <IonIcon slot="icon-only" icon={IonIcons.library} />
          </IonButton>
          <IonButton shape=#round onClick={() => goToAdjacentChapter(false)}>
            <IonIcon slot="icon-only" src=FeatherIcons.chevronLeft />
          </IonButton>
        </IonButtons>
        <IonTitle>
          <div style={{textAlign: "center"}}>
            {`${Books.getBookAbbreviation(reference.book)} ${reference.chapter}`->React.string}
          </div>
        </IonTitle>
        <IonButtons slot="end">
          <IonButton shape=#round onClick={() => goToAdjacentChapter(true)}>
            <IonIcon slot="icon-only" src=FeatherIcons.chevronRight />
          </IonButton>
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
