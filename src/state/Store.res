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

module AppStore = {
  type state = {
    selectedWord: State.selectedWord,
    setSelectedWord: State.selectedWord => unit,
    searchTerms: array<State.searchTerm>,
    setSearchTerms: array<State.searchTerm> => unit,
    addSearchTerm: State.searchTerm => unit,
    deleteSearchTerm: int => unit,
    syntaxFilter: State.syntaxFilter,
    setSyntaxFilter: State.syntaxFilter => unit,
    corpusFilter: State.corpusFilter,
    setCorpusFilter: State.corpusFilter => unit,
    reference: State.reference,
    setReference: State.reference => unit,
    targetReference: State.reference,
    setTargetReference: State.reference => unit,
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
  addSearchTerm: (searchTerm: State.searchTerm) => {
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
  syntaxFilter: State.defaultSyntaxFilter,
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
  corpusFilter: State.defaultCorpusFilter,
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
  showSearchResults: false,
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

let serializeSearchTerms = (searchTerms: array<State.searchTerm>) =>
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
  | "Verse" => State.Verse
  | "Sentence" => Sentence
  | "Clause" => Clause
  | "Phrase" => Phrase
  | "Parallel" => None
  | _ => None
  }
let syntaxFilterVariantToString = (syntaxFilter: State.syntaxFilter) =>
  switch syntaxFilter {
  | Verse => "Verse"
  | Sentence => "Sentence"
  | Clause => "Clause"
  | Phrase => "Phrase"
  | None => "Parallel"
  }
let syntaxFilterToTreeNodeTypeString = (syntaxFilter: State.syntaxFilter) =>
  switch syntaxFilter {
  | Verse => "verse"
  | Sentence => "sentence"
  | Clause => "clause"
  | Phrase => "phrase"
  | None => "parallel"
  }

let corpusFilterStringToVariant = (corpusFilterString: string) =>
  switch corpusFilterString {
  | "Whole Bible" => State.WholeBible
  | "Old Testament" => OldTestament
  | "Pentateuch" => Pentateuch
  | "New Testament" => NewTestament
  | "No Filter" => None
  | _ => None
  }
let corpusFilterVariantToString = (corpusFilter: State.corpusFilter) =>
  switch corpusFilter {
  | WholeBible => "Whole Bible"
  | OldTestament => "Old Testament"
  | Pentateuch => "Pentateuch"
  | NewTestament => "New Testament"
  | None => "No Filter"
  }
let corpusToReferenceString = (corpusFilter: State.corpusFilter) =>
  switch corpusFilter {
  | WholeBible => "gen-rev"
  | OldTestament => "gen-mal"
  | Pentateuch => "gen-deut"
  | NewTestament => "mat-rev"
  | None => ""
  }
