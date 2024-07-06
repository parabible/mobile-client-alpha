module Zustand = {
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

type selectedWord = {id: int, moduleId: int}
type reference = {book: string, chapter: string}
type textualEdition = {id: int, abbreviation: string, visible: bool}
type searchTermDataPoint = {key: string, value: string}
type searchTerm = array<searchTermDataPoint>
module AppStore = {
  type state = {
    selectedWord: selectedWord,
    setSelectedWord: selectedWord => unit,
    searchTerms: array<searchTerm>,
    setSearchTerms: array<searchTerm> => unit,
    addSearchTerm: searchTerm => unit,
    deleteSearchTerm: int => unit,
    reference: reference,
    setReference: (reference) => unit,
    showWordInfo: bool,
    setShowWordInfo: bool => unit,
    showSearchResults: bool,
    setShowSearchResults: bool => unit,
    textualEditions: array<textualEdition>,
    setTextualEditions: array<textualEdition> => unit,
  }
}

module SomeStore = Zustand.MakeStore(AppStore)

let store = SomeStore.create(set => {
  selectedWord: {id: -1, moduleId: -1},
  setSelectedWord: selectedWord =>
    set(state => {
      ...state,
      selectedWord,
    }),
  searchTerms: [],
  setSearchTerms: newSearchTerms =>
    set(state => {
      ...state,
      searchTerms: newSearchTerms,
    }),
  addSearchTerm: searchTermDataPoint =>
    set(state => {
      ...state,
      searchTerms: [...state.searchTerms, searchTermDataPoint],
    }),
    deleteSearchTerm: index => {
      set(state => {
        ...state,
        searchTerms: state.searchTerms->Array.filterWithIndex((_, i) => i !== index),
      })
    },
  reference: {book: "Genesis", chapter: "1"},
  setReference: (reference) =>
    set(state => {
      ...state,
      reference,
    }),
  showWordInfo: false,
  setShowWordInfo: show =>
    set(state => {
      ...state,
      showWordInfo: show,
    }),
  showSearchResults: false,
  setShowSearchResults: show =>
    set(state => {
      ...state,
      showSearchResults: show,
    }),
  textualEditions: [],
  setTextualEditions: editions =>
    set(state => {
      ...state,
      textualEditions: editions,
    }),
})

let serializeSearchTerms = (searchTerms: array<searchTerm>) =>
  searchTerms
  ->Array.mapWithIndex((term, i) =>
    term
    ->Array.map(datapoint =>
      ["t", i->Int.toString, "data", datapoint.key ++ "=" ++ datapoint.value]->Array.join(".")
    )
    ->Array.join("&")
  )
  ->Array.join("&")