open IonicBindings

let getPageLinkRange = (pageNumber, totalPages) => {
  let idealStart = pageNumber - 2
  let idealEnd = pageNumber + 2

  let actualStart = idealStart->Int.clamp(~min=0, ~max=pageNumber)
  let actualEnd = idealEnd->Int.clamp(~min=pageNumber, ~max=totalPages)

  Belt.Array.range(actualStart, actualEnd)
}

@react.component
let make = (~totalPages, ~currentPage, ~setPageNumber) => {
  let pageNumbers = getPageLinkRange(currentPage, totalPages)
  <div className="pagination">
    <IonButton
      disabled={0 == currentPage}
      shape={#round}
      size={#small}
      color={#secondary}
      fill={#outline}
      onClick={_ => setPageNumber(0)}>
      {"«"->React.string}
    </IonButton>
    <IonButton
      disabled={0 == currentPage}
      shape={#round}
      size={#small}
      color={#secondary}
      fill={#outline}
      onClick={_ => setPageNumber(currentPage - 1)}>
      {"<"->React.string}
    </IonButton>
    {pageNumbers
    ->Array.map(i => {
      <IonButton
        key={i->Int.toString}
        shape={#round}
        size={#small}
        disabled={i == currentPage}
        color={i == currentPage ? #medium : #primary}
        fill={#outline}
        onClick={_ => setPageNumber(i)}>
        {i->Int.toString->React.string}
      </IonButton>
    })
    ->React.array}
    <IonButton
      disabled={totalPages == currentPage}
      shape={#round}
      size={#small}
      color={#secondary}
      fill={#outline}
      onClick={_ => setPageNumber(currentPage + 1)}>
      {">"->React.string}
    </IonButton>
    <IonButton
      disabled={totalPages == currentPage}
      shape={#round}
      size={#small}
      color={#secondary}
      fill={#outline}
      onClick={_ => setPageNumber(totalPages)}>
      {"»"->React.string}
    </IonButton>
  </div>
}
