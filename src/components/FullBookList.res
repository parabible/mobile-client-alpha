open IonicBindings

let otBooks = Books.books->Array.slice(~start=0, ~end=39)
let ntBooks = Books.books->Array.slice(~start=39, ~end=66)
let apBooks = Books.books->Array.sliceToEnd(~start=66)

@react.component
let make = (~selectBook: string => unit) => {
  <IonList lines=#none inset={false}>
    <IonItemGroup>
      <IonItemDivider>
        <IonLabel> {"Old Testament"->React.string} </IonLabel>
      </IonItemDivider>
      <div>
        {otBooks
        ->Array.map(item =>
          <IonButton key={item.name} onClick={() => selectBook(item.name)} fill=#clear expand=#full>
            {item.name->React.string}
          </IonButton>
        )
        ->React.array}
      </div>
    </IonItemGroup>
    <IonItemGroup>
      <IonItemDivider>
        <IonLabel> {"New Testament"->React.string} </IonLabel>
      </IonItemDivider>
      <div>
        {ntBooks
        ->Array.map(item =>
          <IonButton key={item.name} onClick={() => selectBook(item.name)} fill=#clear expand=#full>
            {item.name->React.string}
          </IonButton>
        )
        ->React.array}
      </div>
    </IonItemGroup>
    <IonItemGroup>
      <IonItemDivider>
        <IonLabel> {"Apostolic Fathers"->React.string} </IonLabel>
      </IonItemDivider>
      <div>
        {apBooks
        ->Array.map(item =>
          <IonButton key={item.name} onClick={() => selectBook(item.name)} fill=#clear expand=#full>
            {item.name->React.string}
          </IonButton>
        )
        ->React.array}
      </div>
    </IonItemGroup>
  </IonList>
}
