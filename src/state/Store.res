module Store = {
  module type StoreConfig = {
    type state
  }

  module MakeStore = (Config: StoreConfig) => {
    type set = (Config.state => Config.state) => unit
    type selector<'a> = Config.state => 'a

    type store

    external unsafeStoreToAny: store => 'a = "%identity"

    let use = (store: store, selector: selector<'a>): 'a => unsafeStoreToAny(store)(selector)

    @module("zustand")
    external create: (set => Config.state) => store = "create"
  }
}

type textualEditionDisplayOptions = All | English | SourceTexts

module AppStore = {
  type state = {
    selectedWord: State.selectedWord,
    setSelectedWord: State.selectedWord => unit,
    searchTerms: array<SearchTermSerde.searchTerm>,
    setSearchTerms: array<SearchTermSerde.searchTerm> => unit,
    addSearchTerm: SearchTermSerde.searchTerm => unit,
    deleteSearchTerm: int => unit,
    syntaxFilter: State.syntaxFilter,
    setSyntaxFilter: State.syntaxFilter => unit,
    corpusFilter: State.corpusFilter,
    setCorpusFilter: State.corpusFilter => unit,
    reference: Books.reference,
    setReference: Books.reference => unit,
    targetReference: Books.reference,
    setTargetReference: Books.reference => unit,
    chapterLoadingState: State.chapterLoadingState,
    setChapterLoadingState: State.chapterLoadingState => unit,
    showWordInfo: bool,
    setShowWordInfo: bool => unit,
    showSearchResults: bool,
    setShowSearchResults: bool => unit,
    textualEditions: array<State.textualEdition>,
    setTextualEditions: array<State.textualEdition> => unit,
  }
}

module MobileClient = Store.MakeStore(AppStore)

let store = MobileClient.create(set => {
  selectedWord: State.initialSelectedWord,
  setSelectedWord: selectedWord => {
    WindowBindings.LocalStorage.setItem(
      "selectedWord",
      selectedWord->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      selectedWord,
    })
  },
  searchTerms: State.initialSearchTerms,
  setSearchTerms: newSearchTerms => {
    WindowBindings.LocalStorage.setItem(
      "searchTerms",
      newSearchTerms->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      searchTerms: newSearchTerms,
    })
  },
  addSearchTerm: (searchTerm: SearchTermSerde.searchTerm) => {
    set(state => {
      let searchTerms = [...state.searchTerms, searchTerm]
      WindowBindings.LocalStorage.setItem(
        "searchTerms",
        searchTerms->JSON.stringifyAny->Option.getOr(""),
      )
      {
        ...state,
        searchTerms,
      }
    })
  },
  deleteSearchTerm: index =>
    set(state => {
      let searchTerms = state.searchTerms->Array.filterWithIndex((_, i) => i !== index)
      WindowBindings.LocalStorage.setItem(
        "searchTerms",
        searchTerms->JSON.stringifyAny->Option.getOr(""),
      )
      {
        ...state,
        searchTerms,
      }
    }),
  syntaxFilter: State.initialSyntaxFilter,
  setSyntaxFilter: syntaxFilter => {
    WindowBindings.LocalStorage.setItem(
      "syntaxFilter",
      syntaxFilter->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      syntaxFilter,
    })
  },
  corpusFilter: State.initialCorpusFilter,
  setCorpusFilter: corpusFilter => {
    WindowBindings.LocalStorage.setItem(
      "corpusFilter",
      corpusFilter->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      corpusFilter,
    })
  },
  reference: State.initialReference,
  setReference: reference => {
    WindowBindings.LocalStorage.setItem("reference", reference->JSON.stringifyAny->Option.getOr(""))
    set(state => {
      ...state,
      reference,
    })
  },
  targetReference: State.initialReference,
  setTargetReference: reference => {
    WindowBindings.LocalStorage.setItem(
      "targetReference",
      reference->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      targetReference: reference,
    })
  },
  chapterLoadingState: State.Loading,
  setChapterLoadingState: newLoadingState =>
    set(state => {
      ...state,
      chapterLoadingState: newLoadingState,
    }),
  showWordInfo: false,
  setShowWordInfo: show =>
    set(state => {
      ...state,
      showWordInfo: show,
    }),
  showSearchResults: State.showSearchResultsFromUrl,
  setShowSearchResults: show =>
    set(state => {
      ...state,
      showSearchResults: show,
    }),
  textualEditions: State.initialTextualEditions,
  setTextualEditions: editions => {
    WindowBindings.LocalStorage.setItem(
      "textualEditions",
      editions->JSON.stringifyAny->Option.getOr(""),
    )
    set(state => {
      ...state,
      textualEditions: editions,
    })
  },
})
