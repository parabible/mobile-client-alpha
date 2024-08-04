@react.component
let make = (~children: React.element) => {
  let showSearchResults = Store.store->Store.MobileClient.use(state => state.showSearchResults)
  React.useEffect1(() => {
    Url.Pathname.set(showSearchResults ? "search" : "read")
    None
  }, [showSearchResults])

  let reference = Store.store->Store.MobileClient.use(state => state.reference)
  React.useEffect1(() => {
    reference->Console.log
    let abbr = Books.getBookAbbreviation(reference.book)
    let newPath = abbr->String.replaceAll(" ", "") ++ " " ++ reference.chapter
    if newPath != Url.SearchParams.get("ref") {
      Url.SearchParams.set("ref", newPath)
    }
    None
  }, [reference])

  <> {children} </>
}
