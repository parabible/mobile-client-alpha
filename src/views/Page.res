%%raw(`import './Page.css';`)

open IonicBindings

let referenceToElement = (reference: Books.reference) =>
  switch reference.chapter == "0" {
  | true => `${Books.getBookAbbreviation(reference.book)} Pr.`->React.string
  | false => `${Books.getBookAbbreviation(reference.book)} ${reference.chapter}`->React.string
  }

@react.component
let make = () => {
  let ref = React.useRef(Nullable.null)
  let darkMode = Store.store->Store.MobileClient.use(state => state.darkMode)
  let setDarkMode = Store.store->Store.MobileClient.use(state => {
    state.setDarkMode
  })
  let reference = Store.store->Store.MobileClient.use(state => state.reference)
  let targetReference = Store.store->Store.MobileClient.use(state => state.targetReference)
  let setTargetReference = Store.store->Store.MobileClient.use(state => state.setTargetReference)
  let goToAdjacentChapter = forward => {
    let newReference = Books.getAdjacentChapter(targetReference, forward)
    setTargetReference(newReference)
  }
  let chapterLoadingState = Store.store->Store.MobileClient.use(state => state.chapterLoadingState)
  let setShowSearchResults =
    Store.store->Store.MobileClient.use(state => state.setShowSearchResults)

  <IonPage>
    <IonHeader>
      <IonToolbar color={#light}>
        <IonButtons slot="start">
          <IonButton
            className="adjacentChapterButton"
            shape=#round
            onClick={() => goToAdjacentChapter(false)}>
            <IonIcon slot="icon-only" src=FeatherIcons.chevronLeft />
          </IonButton>
          <IonButton
            shape=#round
            size=#large
            style={ReactDOM.Style.make(~height="48px", ())}
            onClick={() => IonicFunctions.menuController.\"open"("book-selector")}>
            {referenceToElement(reference)}
            <div
              className={"target-reference" ++
              (targetReference.book == reference.book &&
                targetReference.chapter == reference.chapter
                ? " ready"
                : "") ++ (chapterLoadingState == Error ? " error" : "")}>
              {referenceToElement(targetReference)}
            </div>
          </IonButton>
          <IonButton
            className="adjacentChapterButton"
            shape=#round
            onClick={() => goToAdjacentChapter(true)}>
            <IonIcon slot="icon-only" src=FeatherIcons.chevronRight />
          </IonButton>
        </IonButtons>
        <IonButtons slot="end">
          <IonButton shape={#round} onClick={_ => setDarkMode(!darkMode)}>
            <IonIcon slot="icon-only" icon={IonIcons.contrast} />
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
        {switch chapterLoadingState {
        | Loading => <IonProgressBar \"type"=#indeterminate />
        | Error => <IonProgressBar \"type"=#determinate value=1. color={#danger} />
        | Ready => <> </>
        }}
      </IonToolbar>
    </IonHeader>
    <IonContent ref={ReactDOM.Ref.domRef(ref)} id="main">
      <ParallelReader contentRef={ref} />
      <SearchResults />
      <IonFab slot=#fixed vertical=#bottom horizontal=#end>
        <IonFabButton onClick={() => setShowSearchResults(true)}>
          <IonIcon icon={IonIcons.search} />
        </IonFabButton>
      </IonFab>
      <WordInfo />
    </IonContent>
  </IonPage>
}
