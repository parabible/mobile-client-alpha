%%raw(`import './Pagination.css';`)

open IonicBindings

let getPageLinkRange = (pageNumber, totalPages) => {
  let idealStart = pageNumber - 2
  let idealEnd = pageNumber + 2

  let actualStart = idealStart->Int.clamp(~min=0, ~max=pageNumber)
  let actualEnd = idealEnd->Int.clamp(~min=pageNumber, ~max=totalPages)

  Belt.Array.range(actualStart, actualEnd)
}
// let pageNumbers = getPageLinkRange(currentPage, totalPages)
// {pageNumbers
// ->Array.map(i => {
//   <IonButton
//     key={i->Int.toString}
//     shape={#round}
//     size={#small}
//     disabled={i == currentPage}
//     color={i == currentPage ? #medium : #primary}
//     fill={#outline}
//     onClick={_ => setPageNumber(i)}>
//     {i->Int.toString->React.string}
//   </IonButton>
// })
// ->React.array}

@react.component
let make = (~totalPages, ~currentPage, ~setPageNumber) => {
  let pageInfoStr = (currentPage + 1)->Int.toString ++ " / " ++ (totalPages + 1)->Int.toString
  <div className="pagination">
    <IonButton
      disabled={0 == currentPage}
      shape={#round}
      size={#small}
      color={#medium}
      fill={#clear}
      onClick={_ => setPageNumber(0)}>
      <IonIcon slot="icon-only" src=FeatherIcons.chevronsLeft />
    </IonButton>
    <IonButton
      disabled={0 == currentPage}
      shape={#round}
      size={#small}
      color={#medium}
      fill={#clear}
      onClick={_ => setPageNumber(currentPage - 1)}>
      <IonIcon slot="icon-only" src=FeatherIcons.chevronLeft />
    </IonButton>
    <div className="page-info"> {pageInfoStr->React.string} </div>
    <IonButton
      disabled={totalPages == currentPage}
      shape={#round}
      size={#small}
      color={#medium}
      fill={#clear}
      onClick={_ => setPageNumber(currentPage + 1)}>
      <IonIcon slot="icon-only" src=FeatherIcons.chevronRight />
    </IonButton>
    <IonButton
      disabled={totalPages == currentPage}
      shape={#round}
      size={#small}
      color={#medium}
      fill={#clear}
      onClick={_ => setPageNumber(totalPages)}>
      <IonIcon slot="icon-only" src=FeatherIcons.chevronsRight />
    </IonButton>
  </div>
}
