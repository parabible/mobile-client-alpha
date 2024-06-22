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
module AppStore = {
  type state = {
    selectedWord: selectedWord,
    setSelectedWord: selectedWord => unit,
    searchLexeme: string,
    setSearchLexeme: string => unit,
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
  searchLexeme: "",
  setSearchLexeme: lexeme =>
    set(state => {
      ...state,
      searchLexeme: lexeme,
    }),
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
