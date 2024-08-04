let updateParamsForSearch = (serializedSearchTerms, syntaxFilter, corpusFilter) => {
  Url.SearchParams.replace(
    serializedSearchTerms ++ "&syntaxFilter=" ++ syntaxFilter ++ "&corpusFilter=" ++ corpusFilter,
  )
}

let updateParamsForRead = (reference: Books.reference) => {
  let abbr = Books.getBookAbbreviation(reference.book)
  let newPath = abbr->String.replaceAll(" ", "") ++ " " ++ reference.chapter
  if newPath != Url.SearchParams.get("ref") {
    Url.SearchParams.replace("ref=" ++ newPath)
  }
}

@react.component
let make = (~children: React.element) => {
  let showSearchResults = Store.store->Store.MobileClient.use(state => state.showSearchResults)
  let reference = Store.store->Store.MobileClient.use(state => state.reference)
  let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
  let serializedSearchTerms = SearchTermSerde.serializeSearchTerms(searchTerms)
  let syntaxFilter = Store.store->Store.MobileClient.use(state => state.syntaxFilter)
  let serializedSyntaxFilter = State.syntaxFilterVariantToString(syntaxFilter)
  let corpusFilter = Store.store->Store.MobileClient.use(state => state.corpusFilter)
  let serializedCorpusFilter = State.corpusFilterVariantToString(corpusFilter)

  React.useEffect1(() => {
    if showSearchResults {
      Url.Pathname.set("search")
    } else {
      Url.Pathname.set("read")
    }
    None
  }, [showSearchResults])

  React.useEffect4(() => {
    if showSearchResults {
      updateParamsForSearch(serializedSearchTerms, serializedSyntaxFilter, serializedCorpusFilter)
    }
    None
  }, (showSearchResults, serializedSearchTerms, serializedSyntaxFilter, serializedCorpusFilter))

  React.useEffect2(() => {
    if !showSearchResults {
      updateParamsForRead(reference)
    }
    None
  }, (showSearchResults, reference))

  <> {children} </>
}
