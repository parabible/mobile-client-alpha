type selectedWord = {id: int, moduleId: int}

type syntaxFilter = Verse | Sentence | Clause | Phrase | None

let availableSyntaxFilters: array<syntaxFilter> = [Phrase, Clause, Sentence, Verse, None]

let defaultSyntaxFilter = "Verse"

type corpusFilter = WholeBible | OldTestament | Pentateuch | NewTestament | None

let availableCorpusFilters: array<corpusFilter> = [
  WholeBible,
  OldTestament,
  Pentateuch,
  NewTestament,
  None,
]

let defaultCorpusFilter = "None"

type reference = {book: string, chapter: string}

type chapterLoadingState = Ready | Loading | Error

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

let decodeSelectedWord = Json.Decode.object(field => {
  id: field.required("id", Json.Decode.int),
  moduleId: field.required("moduleId", Json.Decode.int),
})

let initialSelectedWord =
  WindowBindings.LocalStorage.getItem("selectedWord")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeSelectedWord)
  ->Belt.Result.getWithDefault({id: -1, moduleId: -1})

let showSearchResultsFromUrl = Url.Pathname.get() == "search"

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

let searchTermsFromLocalStorage = (WindowBindings.LocalStorage.getItem("searchTerms")
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
  WindowBindings.LocalStorage.getItem("syntaxFilter")
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
  WindowBindings.LocalStorage.getItem("corpusFilter")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeCorpusFilter)
  ->Belt.Result.getWithDefault(defaultCorpusFilter)
  ->corpusFilterStringToVariant

let initialCorpusFilter = switch (corpusFilterFromUrl, corpusFilterFromLocalStorage) {
| (None, _) => {
    corpusFilterFromLocalStorage
  }
| (_, _) => {
    corpusFilterFromUrl
  }
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
  WindowBindings.LocalStorage.getItem("textualEditions")
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
  WindowBindings.LocalStorage.getItem("reference")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeReference)
  ->Belt.Result.getWithDefault({book: "John", chapter: "1"}),
)
