open IonicBindings

@react.component
let make = (~filterValue: string, ~selectBook: string => unit) => {
    let filteredList = Books.books->Array.filter(b =>
        b.name->String.toLowerCase->String.includes(filterValue->String.toLowerCase)
    )

  filteredList->Array.map(item =>
    <IonButton key={item.name} onClick={() => selectBook(item.name)} fill=#clear expand=#full>
      {item.name->React.string}
    </IonButton>
  )->React.array
}
