type selectedWord = {id: int, moduleId: int}

type syntaxFilter = Verse | Sentence | Clause | Phrase | None

let availableSyntaxFilters: array<syntaxFilter> = [Phrase, Clause, Sentence, Verse, None]

let defaultSyntaxFilter = "Verse"

type corpusFilter = CurrentBook | WholeBible | OldTestament | Pentateuch | NewTestament | None

let availableCorpusFilters: array<corpusFilter> = [
  CurrentBook,
  WholeBible,
  OldTestament,
  Pentateuch,
  NewTestament,
  None,
]

let defaultCorpusFilter = "None"

type reference = {book: string, chapter: string}

type chapterLoadingState = Ready | Loading | Error

let searchTermToFriendlyString = (term: SearchTermSerde.searchTerm) =>
  term.data->Array.map(({value}) => value)->Array.join(" ")

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
  | "Current Book" => CurrentBook
  | "Whole Bible" => WholeBible
  | "Old Testament" => OldTestament
  | "Pentateuch" => Pentateuch
  | "New Testament" => NewTestament
  | "No Filter" => None
  | _ => None
  }

let corpusFilterVariantToString = (corpusFilter: corpusFilter) =>
  switch corpusFilter {
  | CurrentBook => "Current Book"
  | WholeBible => "Whole Bible"
  | OldTestament => "Old Testament"
  | Pentateuch => "Pentateuch"
  | NewTestament => "New Testament"
  | None => "No Filter"
  }

let corpusToReferenceString = (corpusFilter: corpusFilter, currentReference: Books.reference) =>
  switch corpusFilter {
  | CurrentBook => currentReference.book
  | WholeBible => "gen-rev"
  | OldTestament => "gen-mal"
  | Pentateuch => "gen-deut"
  | NewTestament => "mat-rev"
  | None => ""
  }

let decodeSelectedWord = Json.Decode.object(field => {
  id: field.required("id", Json.Decode.int),
  moduleId: field.required("moduleId", Json.Decode.int),
})

let initialSelectedWord =
  Dom.Storage.getItem("selectedWord", Dom.Storage.localStorage)
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeSelectedWord)
  ->Belt.Result.getWithDefault({id: -1, moduleId: -1})

let showSearchResultsFromUrl = Webapi.Dom.location->Webapi.Dom.Location.pathname == "/search"

type dataPoint = {key: string, value: string}

let decodeSearchTermDataPoint = Json.Decode.object(field => {
  key: field.required("key", Json.Decode.string),
  value: field.required("value", Json.Decode.string),
})

type searchTerm = {uuid: string, inverted: bool, data: array<dataPoint>}

let decodeSearchTerms = Json.Decode.array(
  Json.Decode.object(field => {
    uuid: field.required("uuid", Json.Decode.string),
    inverted: field.required("inverted", Json.Decode.bool),
    data: field.required("data", Json.Decode.array(decodeSearchTermDataPoint)),
  }),
)

let searchTermsFromUrl = Url.SearchParams.getAll()->SearchTermSerde.deserializeSearchTermParams

let searchTermsFromLocalStorage = (Dom.Storage.getItem("searchTerms", Dom.Storage.localStorage)
->Option.map(Json.parse)
->Option.getOr(Belt.Result.Ok(Js.Json.null))
->Belt.Result.getWithDefault(Js.Json.null)
->Json.decode(decodeSearchTerms)
->Belt.Result.getWithDefault([]) :> array<SearchTermSerde.searchTerm>)

let initialSearchTerms = if showSearchResultsFromUrl {
  searchTermsFromUrl
} else {
  searchTermsFromLocalStorage
}

let decodeSyntaxFilter = Json.Decode.string

let syntaxFilterFromUrl = syntaxFilterStringToVariant(Url.SearchParams.get("syntaxFilter"))

let syntaxFilterFromLocalStorage =
  Dom.Storage.getItem("syntaxFilter", Dom.Storage.localStorage)
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeSyntaxFilter)
  ->Belt.Result.getWithDefault(defaultSyntaxFilter)
  ->syntaxFilterStringToVariant

let initialSyntaxFilter = switch (syntaxFilterFromUrl, syntaxFilterFromLocalStorage) {
| (None, None) => Verse
| (None, _) => syntaxFilterFromLocalStorage
| (_, _) => syntaxFilterFromUrl
}

let decodeCorpusFilter = Json.Decode.string

let corpusFilterFromUrl = corpusFilterStringToVariant(Url.SearchParams.get("corpusFilter"))

let corpusFilterFromLocalStorage =
  Dom.Storage.getItem("corpusFilter", Dom.Storage.localStorage)
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeCorpusFilter)
  ->Belt.Result.getWithDefault(defaultCorpusFilter)
  ->corpusFilterStringToVariant

let initialCorpusFilter = switch (corpusFilterFromUrl, corpusFilterFromLocalStorage) {
| (None, _) => corpusFilterFromLocalStorage
| (_, _) => corpusFilterFromUrl
}

let defaultEnabledTextualEditions = ["BHSA", "NET", "NA1904", "CAFE", "APF"]

type textualEdition = {id: int, abbreviation: string, visible: bool}

let decodeTextualEditions = Json.Decode.array(
  Json.Decode.object(field => {
    id: field.required("id", Json.Decode.int),
    abbreviation: field.required("abbreviation", Json.Decode.string),
    visible: field.required("visible", Json.Decode.bool),
  }),
)

let initialTextualEditions =
  Dom.Storage.getItem("textualEditions", Dom.Storage.localStorage)
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeTextualEditions)
  ->Belt.Result.getWithDefault([])

let refreshTextualEditions = (textualEditions, setTextualEditions) => {
  let url = "https://dev.parabible.com/api/v2/module"

  let decodeTextualEditionsFromApi = Json.Decode.object(container =>
    {
      "data": container.required(
        "data",
        Json.Decode.array(
          Json.Decode.object(field =>
            {
              "moduleId": field.required("moduleId", Json.Decode.int),
              "abbreviation": field.required("abbreviation", Json.Decode.string),
            }
          ),
        ),
      ),
    }
  )

  ignore(
    Fetch.fetch(url, {method: #GET})
    ->Promise.then(response => {
      response->Fetch.Response.json
    })
    ->Promise.then(data => {
      let d = data->Json.decode(decodeTextualEditionsFromApi)
      switch d {
      | Belt.Result.Error(e) => e->Console.error
      | Belt.Result.Ok(d) => {
          let newTextualEditions = d["data"]->Array.map(m => {
            let t: textualEdition = {
              id: m["moduleId"],
              abbreviation: m["abbreviation"],
              visible: defaultEnabledTextualEditions->Array.includes(m["abbreviation"]),
            }
            t
          })
          switch textualEditions->Array.length {
          | 0 => setTextualEditions(newTextualEditions)
          | _ => {
              // exclude any textual editions that are not in the new data
              let oldTextualEditionsWithoutUnknowns =
                textualEditions->Array.filter(m =>
                  newTextualEditions->Array.find(
                    t => t.abbreviation == m.abbreviation && t.id == m.id,
                  ) != None
                )
              let brandNewTextualEditions =
                newTextualEditions->Array.filter(m =>
                  textualEditions->Array.find(
                    t => t.abbreviation == m.abbreviation && t.id == m.id,
                  ) == None
                )
              let combinedTextualEditions =
                oldTextualEditionsWithoutUnknowns->Array.concat(brandNewTextualEditions)
              setTextualEditions(combinedTextualEditions)
            }
          }
        }
      }
      Promise.resolve()
    }),
  )
}

let decodeReference = (Json.Decode.object(field => {
  book: field.required("book", Json.Decode.string),
  chapter: field.required("chapter", Json.Decode.string),
}) :> Json.Decode.t<Books.reference>)

let referenceFromUrl = (ReferenceParser.parse(Url.SearchParams.get("ref")) :> option<
  Books.reference,
>)

let initialReference = referenceFromUrl->Option.getOr(
  Dom.Storage.getItem("reference", Dom.Storage.localStorage)
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeReference)
  ->Belt.Result.getWithDefault({book: "John", chapter: "1"}),
)

type corpora = OT | NT | ApF

type temporaryTextualEditionData = {
  abbreviation: string,
  language: string,
  corpora: array<corpora>,
  fullname: string,
  source_text: bool,
}
let temporaryTextualEditionData = [
  {
    abbreviation: "BHSA",
    language: "Hebrew",
    corpora: [OT],
    fullname: "Biblia Hebraica Stuttgartensia Amstelodamensis (tagged)",
    source_text: true,
  },
  {
    abbreviation: "NET",
    language: "English",
    corpora: [OT, NT],
    fullname: "New English Translation",
    source_text: false,
  },
  {
    abbreviation: "NA1904",
    language: "Greek",
    corpora: [NT],
    fullname: "Nestle-Aland 1904 (tagged)",
    source_text: true,
  },
  {
    abbreviation: "CAFE",
    language: "English",
    corpora: [ApF],
    fullname: "Contemporary Apostolic Fathers Edition",
    source_text: false,
  },
  {
    abbreviation: "RVG",
    language: "Spanish",
    corpora: [OT, NT],
    fullname: "Reina Valera Gómez",
    source_text: false,
  },
  {
    abbreviation: "CUNPT",
    language: "Chinese",
    corpora: [OT, NT],
    fullname: "Chinese Union Version (Traditional)",
    source_text: false,
  },
  {
    abbreviation: "CUNPS",
    language: "Chinese",
    corpora: [OT, NT],
    fullname: "Chinese Union Version (Simplified)",
    source_text: false,
  },
  {
    abbreviation: "APF",
    language: "Greek",
    corpora: [ApF],
    fullname: "Apostolic Fathers (tagged)",
    source_text: true,
  },
  {
    abbreviation: "LAPF",
    language: "English",
    corpora: [ApF],
    fullname: "Lightfoot's Translation of the Apostolic Fathers",
    source_text: false,
  },
  {
    abbreviation: "ULT",
    language: "English",
    corpora: [OT, NT],
    fullname: "UnfoldingWord Literal Translation",
    source_text: false,
  },
  {
    abbreviation: "BSB",
    language: "English",
    corpora: [OT, NT],
    fullname: "Berean Standard Bible",
    source_text: false,
  },
  {
    abbreviation: "LXXR",
    language: "Greek",
    corpora: [OT],
    fullname: "Rahlfs Septuagint (tagged)",
    source_text: true,
  },
  {
    abbreviation: "UST",
    language: "English",
    corpora: [OT, NT],
    fullname: "UnfoldingWord Simplified Translation",
    source_text: false,
  },
  {
    abbreviation: "JPS",
    language: "English",
    corpora: [OT],
    fullname: "Jewish Publication Society",
    source_text: false,
  },
]
