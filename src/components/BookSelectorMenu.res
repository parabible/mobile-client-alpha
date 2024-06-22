open IonicBindings

let getEventValue = e => {
  let target = e->JsxEvent.Form.target
  (target["value"]: string)
}

@react.component
let make = () => {
  // let inputRef = React.useRef(Js.Nullable.null);
  let setReference = Zustand.store->Zustand.SomeStore.use(state => state.setReference)
  let (searchValue, setSearchValue) = React.useState(_ => "")
  let filterIsApplied = searchValue->String.length > 0
  let selectBook = book => setReference({book, chapter: "1"})
  let onSearchInput = event => {
    let value = event->getEventValue
    setSearchValue(_ => value)
  }

  <IonMenu side="start" menuId="book-selector" contentId="main" \"type"="overlay">
    <IonContent className="ion-padding">
      <IonSearchbar onIonInput={onSearchInput} />
      {filterIsApplied
        ? <FilteredBookList filterValue={searchValue} selectBook={selectBook} />
        : <FullBookList selectBook={selectBook} />}
    </IonContent>
  </IonMenu>
}
