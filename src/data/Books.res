type book = {
  name: string,
  abbreviation: string,
  chapters: int,
  hasPrologue: bool,
}

type booksFile = {default: array<option<book>>}

@module external booksFile: Js.Json.t = "./books.json"

let booksList = booksFile->Json.decode(
  Json.Decode.object(field => {
    default: field.required(
      "default",
      Json.Decode.array(
        Json.Decode.option(
          Json.Decode.object(field => {
            name: field.required("name", Json.Decode.string),
            abbreviation: field.required("abbreviation", Json.Decode.string),
            chapters: field.required("chapters", Json.Decode.int),
            hasPrologue: field.optional("hasPrologue", Json.Decode.bool)->Option.getOr(false),
          }),
        ),
      ),
    ),
  }),
)

let allBooks = switch booksList {
| Belt.Result.Ok(b) => b.default
| Belt.Result.Error(e) => {
    e->Console.error
    []
  }
}

let books = allBooks->Array.filterMap(b => b)

type bookChapterPair = {
  book: string,
  chapter: string,
}
let allChapters: array<bookChapterPair> =
  books
  ->Array.map(b =>
    (
      b.hasPrologue ? Belt.Array.range(0, b.chapters - 1) : Belt.Array.range(1, b.chapters)
    )->Array.map(c => {
      chapter: c->Int.toString,
      book: b.name,
    })
  )
  ->Array.flat

allChapters->Console.log

let getAdjacentChapter: (State.reference, bool) => State.reference = (
  reference: State.reference,
  forward,
) => {
  let bcPairIndex =
    allChapters->Array.findIndex((bcp: bookChapterPair) =>
      bcp.book === reference.book && bcp.chapter === reference.chapter
    ) + (forward ? 1 : -1)
  let functionalBcPairIndex = bcPairIndex >= allChapters->Array.length ? 0 : bcPairIndex

  (allChapters
  ->Array.at(functionalBcPairIndex)
  ->Option.getOr({
    chapter: "1",
    book: "Genesis",
  }) :> State.reference)
}

let getBookAbbreviation = book => {
  let bookObj = books->Array.find(b => b.name === book)
  switch bookObj {
  | Some(b) => b.abbreviation
  | None => book
  }
}

let ridToRef = rid => {
  let book = rid / 1000000 - 1
  let chapter = mod(rid / 1000, 1000)
  let verse = mod(rid, 1000)

  let bookObj =
    allBooks
    ->Array.get(book)
    ->Option.getOr(None)
    ->Option.getOr({
      name: "Unknown",
      abbreviation: "Unk",
      chapters: 0,
      hasPrologue: false,
    })

  bookObj.name ++ " " ++ chapter->Int.toString ++ ":" ++ verse->Int.toString
}
