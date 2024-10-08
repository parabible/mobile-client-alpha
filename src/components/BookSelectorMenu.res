%%raw(`import './BookSelectorMenu.css';`)

open IonicBindings

let clearSearchInput = (currentSearchInputRef: Dom.element) => {
  currentSearchInputRef->Webapi.Dom.Element.setNodeValue(Js.Value(""))
}

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
  let inputRef = React.useRef(Js.Nullable.null)
  let (currentMode, setCurrentMode) = React.useState(_ => Book)
  let setTargetReference = Store.store->Store.MobileClient.use(state => state.setTargetReference)
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
  let resetSearch = () => {
    setSelectedBookState(_ => None)
    setCurrentMode(_ => Book)
    setSearchValue(_ => "")
    switch inputRef.current {
    | Null | Undefined => ()
    | Value(current) => clearSearchInput(current)
    }
  }
  let onChapterSelect = chapter => {
    switch selectedBook {
    | Some(book) => {
        setTargetReference({book, chapter: chapter->Int.toString})
        setSelectedBookState(_ => None)
        resetSearch()
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

  <IonMenu
    side="start"
    menuId="book-selector"
    contentId="main"
    \"type"="overlay"
    ionDidClose={{emit: _ => resetSearch()}}>
    <IonContent className="ion-padding">
      <IonSearchbar ref={ReactDOM.Ref.domRef(inputRef)} onIonInput={onSearchInput} />
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
