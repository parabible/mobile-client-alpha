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
type syntaxFilter = Verse | Sentence | Clause | Phrase | None
let availableSyntaxFilters: array<syntaxFilter> = [Phrase, Clause, Sentence, Verse, None]
let defaultSyntaxFilter = Verse
type corpusFilter = WholeBible | OldTestament | Pentateuch | NewTestament | None
let availableCorpusFilters: array<corpusFilter> = [
  WholeBible,
  OldTestament,
  Pentateuch,
  NewTestament,
  None,
]
let defaultCorpusFilter: corpusFilter = None
type reference = {book: string, chapter: string}
type textualEdition = {id: int, abbreviation: string, visible: bool}
type searchTermDataPoint = {key: string, value: string}
type searchTerm = {
  inverted: bool,
  data: array<searchTermDataPoint>,
}
module AppStore = {
  type state = {
    selectedWord: selectedWord,
    setSelectedWord: selectedWord => unit,
    searchTerms: array<searchTerm>,
    setSearchTerms: array<searchTerm> => unit,
    addSearchTerm: searchTerm => unit,
    deleteSearchTerm: int => unit,
    syntaxFilter: syntaxFilter,
    setSyntaxFilter: syntaxFilter => unit,
    corpusFilter: corpusFilter,
    setCorpusFilter: corpusFilter => unit,
    reference: reference,
    setReference: reference => unit,
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
  syntaxFilter: defaultSyntaxFilter,
  setSyntaxFilter: syntaxFilter => {
    set(state => {
      ...state,
      syntaxFilter,
    })
  },
  corpusFilter: defaultCorpusFilter,
  setCorpusFilter: corpusFilter => {
    set(state => {
      ...state,
      corpusFilter,
    })
  },
  reference: {book: "Genesis", chapter: "1"},
  setReference: reference =>
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
    [
      ...term.data->Array.map(datapoint =>
        ["t", i->Int.toString, "data", datapoint.key ++ "=" ++ datapoint.value]->Array.join(".")
      ),
      ["t", i->Int.toString, "inverted" ++ "=" ++ term.inverted->String.make]->Array.join("."),
    ]->Array.join("&")
  )
  ->Array.join("&")

let syntaxFilterStringToVariant = (syntaxFilterString: string) =>
  switch syntaxFilterString {
  | "Verse" => Verse
  | "Sentence" => Sentence
  | "Clause" => Clause
  | "Phrase" => Phrase
  | "Parallel" => None
  | _ => None
  }
let syntaxFilterVariantToString = (syntaxFilter: syntaxFilter) =>
  switch syntaxFilter {
  | Verse => "Verse"
  | Sentence => "Sentence"
  | Clause => "Clause"
  | Phrase => "Phrase"
  | None => "Parallel"
  }
let syntaxFilterToTreeNodeTypeString = (syntaxFilter: syntaxFilter) =>
  switch syntaxFilter {
  | Verse => "verse"
  | Sentence => "sentence"
  | Clause => "clause"
  | Phrase => "phrase"
  | None => "parallel"
  }

let corpusFilterStringToVariant = (corpusFilterString: string) =>
  switch corpusFilterString {
  | "Whole Bible" => WholeBible
  | "Old Testament" => OldTestament
  | "Pentateuch" => Pentateuch
  | "New Testament" => NewTestament
  | "No Filter" => None
  | _ => None
  }
let corpusFilterVariantToString = (corpusFilter: corpusFilter) =>
  switch corpusFilter {
  | WholeBible => "Whole Bible"
  | OldTestament => "Old Testament"
  | Pentateuch => "Pentateuch"
  | NewTestament => "New Testament"
  | None => "No Filter"
  }
let corpusToReferenceString = (corpusFilter: corpusFilter) =>
  switch corpusFilter {
  | WholeBible => "gen-rev"
  | OldTestament => "gen-mal"
  | Pentateuch => "gen-deut"
  | NewTestament => "mat-rev"
  | None => ""
  }
