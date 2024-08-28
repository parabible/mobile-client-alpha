type book = {
  name: string,
  abbreviation: string,
  chapters: int,
  hasPrologue: bool,
}

type reference = {
  book: string,
  chapter: string,
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
  chapters: string,
}
let allChapters: array<bookChapterPair> =
  books
  ->Array.map(b =>
    (
      b.hasPrologue ? Belt.Array.range(0, b.chapters - 1) : Belt.Array.range(1, b.chapters)
    )->Array.map(c => {
      chapters: c->Int.toString,
      book: b.name,
    })
  )
  ->Array.flat

let getAdjacentChapter: (reference, bool) => reference = (reference: reference, forward) => {
  let bcPairIndex =
    allChapters->Array.findIndex((bcp: bookChapterPair) =>
      bcp.book === reference.book && bcp.chapters === reference.chapter
    ) + (forward ? 1 : -1)
  let functionalBcPairIndex = bcPairIndex >= allChapters->Array.length ? 0 : bcPairIndex

  switch allChapters->Array.at(functionalBcPairIndex) {
  | Some(bcPair) => {
      book: bcPair.book,
      chapter: bcPair.chapters,
    }
  | None => {
      book: "Genesis",
      chapter: "1",
    }
  }
}

let getBookAbbreviation = book => {
  let bookObj = books->Array.find(b => b.name === book)
  switch bookObj {
  | Some(b) => b.abbreviation
  | None => book
  }
}

let ridToReferenceString = rid => {
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

let ridToBookChapterReference = rid => {
  let book = rid / 1000000 - 1
  let chapter = mod(rid / 1000, 1000)

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

  {
    book: bookObj.name,
    chapter: chapter->Int.toString,
  }
}
