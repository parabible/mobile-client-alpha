type reference = {
  book: string,
  chapter: string,
}

type corpora = OT | NT | ApF

let parse: string => option<reference> = (reference: string) => {
  let parts = reference->String.split(" ")
  let bookAbbreviation = parts->Array.get(0)

  let book = switch bookAbbreviation {
  | Some(bookAbbreviation) =>
    Books.books->Array.find(b => b.abbreviation->String.replaceAll(" ", "") == bookAbbreviation)
  | None => None
  }

  switch book {
  | Some(book) => {
      let chapter = parts->Array.get(1)->Option.getOr("1")->Int.fromString->Option.getOr(1)
      // chapter must be less that book.chapters
      let offset = book.hasPrologue ? 0 : 1
      let chapter = chapter < offset ? offset : chapter
      let chapter = chapter > book.chapters + offset ? 0 : chapter
      Some({
        book: book.name,
        chapter: chapter->Int.toString,
      })
    }
  | None => None
  }
}

let getCorpusFromReference = (reference: Books.reference) => {
  let book = reference.book
  let index = Books.books->Array.findIndex(b => b.name == book)
  if index < 0 {
    None
  } else if index < 39 {
    Some(OT)
  } else if index < 66 {
    Some(NT)
  } else {
    Some(ApF)
  }
}
