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
    darkMode: bool,
    setDarkMode: bool => unit,
  }
}

module MobileClient = Store.MakeStore(AppStore)

let store = MobileClient.create(set => {
  selectedWord: State.initialSelectedWord,
  setSelectedWord: selectedWord => {
    Dom.Storage.setItem(
      "selectedWord",
      selectedWord->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      selectedWord,
    })
  },
  searchTerms: State.initialSearchTerms,
  setSearchTerms: newSearchTerms => {
    Dom.Storage.setItem(
      "searchTerms",
      newSearchTerms->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      searchTerms: newSearchTerms,
    })
  },
  addSearchTerm: (searchTerm: SearchTermSerde.searchTerm) => {
    set(state => {
      let searchTerms = [...state.searchTerms, searchTerm]
      Dom.Storage.setItem(
        "searchTerms",
        searchTerms->JSON.stringifyAny->Option.getOr(""),
        Dom.Storage.localStorage,
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
      Dom.Storage.setItem(
        "searchTerms",
        searchTerms->JSON.stringifyAny->Option.getOr(""),
        Dom.Storage.localStorage,
      )
      {
        ...state,
        searchTerms,
      }
    }),
  syntaxFilter: State.initialSyntaxFilter,
  setSyntaxFilter: syntaxFilter => {
    Dom.Storage.setItem(
      "syntaxFilter",
      syntaxFilter->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      syntaxFilter,
    })
  },
  corpusFilter: State.initialCorpusFilter,
  setCorpusFilter: corpusFilter => {
    Dom.Storage.setItem(
      "corpusFilter",
      corpusFilter->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      corpusFilter,
    })
  },
  reference: State.initialReference,
  setReference: reference => {
    Dom.Storage.setItem(
      "reference",
      reference->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      reference,
    })
  },
  targetReference: State.initialReference,
  setTargetReference: targetReference => {
    Dom.Storage.setItem(
      "targetReference",
      targetReference->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      targetReference,
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
    Dom.Storage.setItem(
      "textualEditions",
      editions->JSON.stringifyAny->Option.getOr(""),
      Dom.Storage.localStorage,
    )
    set(state => {
      ...state,
      textualEditions: editions,
    })
  },
  darkMode: WindowBindings.matchMedia("(prefers-color-scheme: dark)").matches,
  setDarkMode: darkMode =>
    set(state => {
      Dom.Storage.setItem(
        "darkMode",
        darkMode->JSON.stringifyAny->Option.getOr(""),
        Dom.Storage.localStorage,
      )
      {
        ...state,
        darkMode,
      }
    }),
})
