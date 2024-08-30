open IonicBindings

module OnlyTheMostRecentSearchTerm = {
  @react.component
  let make = () => {
    let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
    let setSearchTerms = Store.store->Store.MobileClient.use(state => state.setSearchTerms)
    let searchTermsLengthStr = searchTerms->Array.length->Int.toString
    let mostRecentSearchTerm = searchTerms->Array.at(-1)
    let recentButton = switch mostRecentSearchTerm {
    | Some(term) =>
      <a
        href="#"
        className="text-blue-500 hover:text-blue-700"
        onClick={_ => {
          setSearchTerms([term])
        }}>
        {("Only search for " ++ term->State.searchTermToFriendlyString)->React.string}
      </a>
    | None => <> </>
    }
    switch searchTerms->Array.length > 1 {
    | true =>
      <div className="border-2 rounded m-2 p-2 text-center">
        <div> {`You have ${searchTermsLengthStr} search terms.`->React.string} </div>
        <div> {recentButton} </div>
      </div>
    | false => <> </>
    }
  }
}

module DeleteASearchTerm = {
  @react.component
  let make = () => {
    let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
    let setSearchTerms = Store.store->Store.MobileClient.use(state => state.setSearchTerms)

    switch searchTerms->Array.length > 1 {
    | true =>
      <div className="border-2 rounded m-2 p-2 text-center">
        <div> {`You could remove a search term:`->React.string} </div>
        <IonList>
          {searchTerms
          ->Array.mapWithIndex((term, i) =>
            <IonItem key={i->Int.toString}>
              <IonLabel> {term->State.searchTermToFriendlyString->React.string} </IonLabel>
              <IonButton
                slot={#end}
                color={#danger}
                onClick={_ => {
                  setSearchTerms(searchTerms->Array.filterWithIndex((_, j) => i != j))
                }}>
                <IonIcon slot="icon-only" icon={IonIcons.trash} />
              </IonButton>
            </IonItem>
          )
          ->React.array}
        </IonList>
      </div>
    | false => <> </>
    }
  }
}

module BroadenSyntax = {
  @react.component
  let make = () => {
    let syntaxFilter = Store.store->Store.MobileClient.use(state => state.syntaxFilter)
    let setSyntaxFilter = Store.store->Store.MobileClient.use(state => state.setSyntaxFilter)

    switch syntaxFilter {
    | None => <> </>
    | Verse =>
      <div className="border-2 rounded m-2 p-2 text-center">
        <div>
          {`You are currently searching for terms in the same ${syntaxFilter->State.syntaxFilterVariantToString}.`->React.string}
        </div>
        <div>
          <a
            href="#"
            className="text-blue-500 hover:text-blue-700"
            onClick={_ => {
              setSyntaxFilter(None)
            }}>
            {`Clear syntax filter`->React.string}
          </a>
        </div>
      </div>
    | _ =>
      <div className="border-2 rounded m-2 p-2 text-center">
        <div>
          {`You are currently searching for terms in the same ${syntaxFilter->State.syntaxFilterVariantToString}.`->React.string}
        </div>
        <div>
          <a
            href="#"
            className="text-blue-500 hover:text-blue-700"
            onClick={_ => {
              setSyntaxFilter(Verse)
            }}>
            {`Search for terms within a ${Verse->State.syntaxFilterVariantToString}`->React.string}
          </a>
        </div>
      </div>
    }
  }
}

module BroadenCorpus = {
  @react.component
  let make = () => {
    let corpusFilter = Store.store->Store.MobileClient.use(state => state.corpusFilter)
    let setCorpusFilter = Store.store->Store.MobileClient.use(state => state.setCorpusFilter)

    switch corpusFilter {
    | None => <> </>
    | _ =>
      <div className="border-2 rounded m-2 p-2 text-center">
        <div>
          {`You are currently searching within the `->React.string}
          <b> {corpusFilter->State.corpusFilterVariantToString->React.string} </b>
        </div>
        <div>
          <IonButton id="book-filter-trigger-alert" expand={#full}>
            {`Change corpus filter`->React.string}
          </IonButton>
          <IonAlert
            trigger="book-filter-trigger-alert"
            header="Corpus Filter"
            inputs={State.availableCorpusFilters->Array.map(f => {
              \"type": #radio,
              label: State.corpusFilterVariantToString(f),
              value: State.corpusFilterVariantToString(f),
              checked: corpusFilter == f,
            })}
            buttons={["OK"]}
            onDidDismiss={eventDetail => {
              setCorpusFilter(State.corpusFilterStringToVariant(eventDetail.detail.data.values))
            }}
          />
        </div>
      </div>
    }
  }
}

@react.component
let make = (~show: bool, ~onDismiss: unit => unit) => {
  <IonModal isOpen={show} onDidDismiss={onDismiss} className="fullscreen-modal">
    <IonHeader>
      <IonToolbar color={#light}>
        <IonButtons slot="start">
          <IonButton shape=#round onClick={onDismiss}>
            <IonIcon slot="icon-only" icon={IonIcons.arrowBack} />
          </IonButton>
        </IonButtons>
        <IonTitle> {`Search Suggestions`->React.string} </IonTitle>
      </IonToolbar>
    </IonHeader>
    <IonContent className="ion-padding">
      <OnlyTheMostRecentSearchTerm />
      <DeleteASearchTerm />
      <BroadenSyntax />
      <BroadenCorpus />
    </IonContent>
  </IonModal>
}
