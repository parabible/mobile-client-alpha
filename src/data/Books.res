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

let getAdjacentChapter: (Zustand.reference, bool) => Zustand.reference = (
  reference: Zustand.reference,
  forward,
) => {
  let bookIndex = books->Array.findIndex(b => b.name === reference.book)
  switch books->Array.get(bookIndex) {
  | Some(bookAtIndex) => {
      let newChapter = reference.chapter->Int.fromString->Option.getOr(1) + (forward ? 1 : -1)
      if newChapter + (bookAtIndex.hasPrologue ? 1 : 0) < 1 {
        if reference.book === "Genesis" {
          // Loop back to Revelation (we don't loop to apostolic fathers)
          {
            chapter: "22",
            book: "Revelation",
          }
        } else {
          switch books->Array.get(bookIndex - 1) {
          | Some(previousBook) => {
              book: previousBook.name,
              chapter: bookAtIndex.hasPrologue
                ? previousBook.chapters->Int.toString
                : (previousBook.chapters - 1)->Int.toString,
            }
          | None => {
              "Something went wrong identifying this book."->Console.error
              {
                book: "Genesis",
                chapter: "1",
              }
            }
          }
        }
      } else if newChapter >= bookAtIndex.chapters - (bookAtIndex.hasPrologue ? 1 : 0) {
        if bookIndex >= books->Array.length {
          // Loop back to Genesis
          {
            chapter: "1",
            book: "Genesis",
          }
        } else {
          switch books->Array.get(bookIndex + 1) {
          | Some(nextBook) => {
              book: nextBook.name,
              chapter: nextBook.hasPrologue ? "0" : "1",
            }
          | None => {
              "Something went wrong identifying this book."->Console.error
              {
                book: "Genesis",
                chapter: "1",
              }
            }
          }
        }
      } else {
        {book: reference.book, chapter: newChapter->Int.toString}
      }
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
