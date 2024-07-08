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
                  newTextualEditions->Array.find(t => t.abbreviation == m.abbreviation) != None
                )
              let brandNewTextualEditions =
                newTextualEditions->Array.filter(m =>
                  textualEditions->Array.find(t => t.abbreviation == m.abbreviation) == None
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
