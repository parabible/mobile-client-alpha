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
  uuid: string,
  inverted: bool,
  data: array<searchTermDataPoint>,
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

let decodeSearchTermDataPoint = Json.Decode.object(field => {
  key: field.required("key", Json.Decode.string),
  value: field.required("value", Json.Decode.string),
})

let decodeSearchTerms = Json.Decode.array(
  Json.Decode.object(field => {
    uuid: field.required("uuid", Json.Decode.string),
    inverted: field.required("inverted", Json.Decode.bool),
    data: field.required("data", Json.Decode.array(decodeSearchTermDataPoint)),
  }),
)

let initialSearchTerms =
  WindowBindings.LocalStorage.getItem("searchTerms")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeSearchTerms)
  ->Belt.Result.getWithDefault([])

let decodeSyntaxFilter = Json.Decode.string

let initialSyntaxFilter =
  WindowBindings.LocalStorage.getItem("syntaxFilter")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeSyntaxFilter)
  ->Belt.Result.getWithDefault("Verse")

let decodeCorpusFilter = Json.Decode.string

let initialCorpusFilter =
  WindowBindings.LocalStorage.getItem("corpusFilter")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeCorpusFilter)
  ->Belt.Result.getWithDefault("None")

let defaultEnabledTextualEditions = ["BHSA", "NET", "NA1904", "CAFE", "APF"]

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

let decodeReference = Json.Decode.object(field => {
  book: field.required("book", Json.Decode.string),
  chapter: field.required("chapter", Json.Decode.string),
})

let initialReference =
  WindowBindings.LocalStorage.getItem("reference")
  ->Option.map(Json.parse)
  ->Option.getOr(Belt.Result.Ok(Js.Json.null))
  ->Belt.Result.getWithDefault(Js.Json.null)
  ->Json.decode(decodeReference)
  ->Belt.Result.getWithDefault({book: "John", chapter: "1"})