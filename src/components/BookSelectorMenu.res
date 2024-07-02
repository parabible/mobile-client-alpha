%%raw(`import './BookSelectorMenu.css';`)

open IonicBindings

let getEventValue = e => {
  let target = e->JsxEvent.Form.target
  (target["value"]: string)
}

module ChapterSelector = {
  @react.component
  let make = (~onChapterSelect: int => unit, ~onBack: unit => unit, ~selectedBook: string) => {
    let book = Books.books->Array.find(b => b.name === selectedBook)
    switch book {
    | None => <div> {"Could not find book"->React.string} </div>
    | Some(b) =>
      let chapters = b.hasPrologue
        ? Belt.Array.range(0, b.chapters - 1)
        : Belt.Array.range(1, b.chapters)
      <div>
        <IonButton expand={#full} fill={#clear} onClick={onBack}>
          {"Back"->React.string}
        </IonButton>
        <div className="chapter-buttons">
          {chapters
          ->Array.map(i => {
            <IonButton fill={#clear} key={i->Int.toString} onClick={_ => onChapterSelect(i)}>
              {switch i {
              | 0 => "Pr."->React.string
              | _ => i->Int.toString->React.string
              }}
            </IonButton>
          })
          ->React.array}
        </div>
      </div>
    }
  }
}

type mode = Book | Chapter

@react.component
let make = () => {
  // let inputRef = React.useRef(Js.Nullable.null);
  let (currentMode, setCurrentMode) = React.useState(_ => Book)
  let setReference = Zustand.store->Zustand.SomeStore.use(state => state.setReference)
  let (searchValue, setSearchValue) = React.useState(_ => "")
  let filterIsApplied = searchValue->String.length > 0
  let (selectedBook, setSelectedBookState) = React.useState(_ => None)
  let setSelectedBook = book => {
    setSelectedBookState(_ => Some(book))
    setCurrentMode(_ => Chapter)
  }
  let onSearchInput = event => {
    let value = event->getEventValue
    setSearchValue(_ => value)
  }
  let onChapterSelect = chapter => {
    switch selectedBook {
    | Some(book) => {
        setReference({book, chapter: chapter->Int.toString})
        IonicFunctions.menuController.close("book-selector")
      }
    | _ => {
        "Could not set reference"->Console.error
        selectedBook->Console.error
        chapter->Console.error
      }
    }
  }

  let bookSelector = filterIsApplied
    ? <FilteredBookList filterValue={searchValue} selectBook={setSelectedBook} />
    : <FullBookList selectBook={setSelectedBook} />

  <IonMenu side="start" menuId="book-selector" contentId="main" \"type"="overlay">
    <IonContent className="ion-padding">
      <IonSearchbar onIonInput={onSearchInput} />
      {switch (currentMode, selectedBook) {
      | (Book, _) | (Chapter, None) => bookSelector
      | (Chapter, Some(book)) =>
        <ChapterSelector
          onChapterSelect={onChapterSelect}
          selectedBook={book}
          onBack={_ => setCurrentMode(_ => Book)}
        />
      }}
    </IonContent>
  </IonMenu>
}
