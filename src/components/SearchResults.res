%%raw(`import './SearchResults.css';`)

open IonicBindings

let pageSizeConstant = 10

type teMatch = array<TextObject.textObject>

type resultRow = array<teMatch>

type termSearchResult = {
  count: int,
  matchingText: array<resultRow>,
}

let decodeTermSearchResult = Json.Decode.object(field => {
  count: field.required("count", Json.Decode.int),
  matchingText: field.required(
    "matchingText",
    Json.Decode.array(Json.Decode.array(Json.Decode.array(TextObject.decodeTextObject))),
  ),
})

let getUrl = (
  ~serializedSearchTerms,
  ~textualEditionAbbreviations,
  ~syntaxFilter: State.syntaxFilter,
  ~corpusFilter: State.corpusFilter,
  ~pageNumber,
  ~pageSize,
) => {
  let modules = `modules=${textualEditionAbbreviations}`
  let syntaxFilter = `treeNodeType=${Store.syntaxFilterToTreeNodeTypeString(syntaxFilter)}`
  let corpusFilter = switch corpusFilter {
  | None => ""
  | corpusFilter => `corpusFilter=${Store.corpusToReferenceString(corpusFilter)}`
  }
  let pageNumber = `page=${pageNumber->Int.toString}`
  let pageSize = `pageSize=${pageSize->Int.toString}`

  let vars =
    [serializedSearchTerms, modules, syntaxFilter, corpusFilter, pageNumber, pageSize]
    ->Array.filter(s => s != "")
    ->Array.join("&")

  `https://dev.parabible.com/api/v2/termSearch?${vars}`
}

let getSearchResults = async (
  ~serializedSearchTerms,
  ~syntaxFilter,
  ~corpusFilter,
  ~textualEditionAbbreviations,
  ~pageNumber,
  ~pageSize,
) => {
  let url = getUrl(
    ~serializedSearchTerms,
    ~textualEditionAbbreviations,
    ~syntaxFilter,
    ~corpusFilter,
    ~pageNumber,
    ~pageSize,
  )
  let response = await Fetch.fetch(url, {method: #GET})
  let json = await response->Fetch.Response.json
  json->Json.decode(decodeTermSearchResult)
}

let getFirstRidForRow = (row: resultRow) =>
  switch row->Array.at(0)->Option.getOr([])->Array.at(0) {
  | Some(textObject) => textObject.rid
  | None => 0
  }

module CenteredDiv = {
  @react.component
  let make = (~children) => {
    <div className="centered"> {children} </div>
  }
}

module LoadingIndicator = {
  @react.component
  let make = (~visible) => {
    switch visible {
    | true =>
      <div className="overlay">
        <IonSpinner name={#dots} color={#primary} />
      </div>
    | false => <> </>
    }
  }
}

module SearchTermItem = {
  @react.component
  let make = (~term: State.searchTerm, ~invertSearchTerm, ~editSearchTerm, ~dropSearchTerm) => {
    <IonItemSliding>
      <IonItem detail={true}>
        <IonLabel>
          <h2>
            {term.data
            ->Array.map(({value}) => `${value}`)
            ->Array.join(" ")
            ->React.string}
          </h2>
          <p> {(term.inverted ? "inverted" : "")->React.string} </p>
        </IonLabel>
      </IonItem>
      <IonItemOptions side=#end>
        <IonItemOption onClick={invertSearchTerm}>
          <IonIcon slot="icon-only" icon={term.inverted ? IonIcons.flashOff : IonIcons.flash} />
        </IonItemOption>
        // <IonItemOption onClick={editSearchTerm}>
        //   <IonIcon slot="icon-only" icon={IonIcons.options} />
        // </IonItemOption>
        <IonItemOption color={#danger} onClick={dropSearchTerm} expandable={true}>
          <IonIcon slot="icon-only" icon={IonIcons.trash} />
        </IonItemOption>
      </IonItemOptions>
    </IonItemSliding>
  }
}

// module PopoverSelectList = {
//   @react.component
//   let make = (~trigger, ~children) => {
//     <IonPopover trigger={trigger} dismissOnSelect={false} side={#bottom} alignment={#center}>
//       <IonContent>
//         <IonList> {children} </IonList>
//       </IonContent>
//     </IonPopover>
//   }
// }

module SearchMenu = {
  @react.component
  let make = () => {
    let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
    let deleteSearchTerm = Store.store->Store.MobileClient.use(state => state.deleteSearchTerm)
    let setSearchTerms = Store.store->Store.MobileClient.use(state => state.setSearchTerms)
    let invertSearchTerm = index =>
      setSearchTerms(
        searchTerms->Array.mapWithIndex((term, i) => {
          if i == index {
            let term: State.searchTerm = {
              uuid: term.uuid,
              inverted: !term.inverted,
              data: term.data,
            }
            term
          } else {
            term
          }
        }),
      )
    let syntaxFilter = Store.store->Store.MobileClient.use(state => state.syntaxFilter)
    let setSyntaxFilter = Store.store->Store.MobileClient.use(state => state.setSyntaxFilter)
    let corpusFilter = Store.store->Store.MobileClient.use(state => state.corpusFilter)
    let setCorpusFilter = Store.store->Store.MobileClient.use(state => state.setCorpusFilter)
    <IonPopover trigger="popover-button" dismissOnSelect={false}>
      <IonContent>
        <IonList>
          <IonItemGroup>
            <IonItem button={true} id="syntax-filter-trigger-alert">
              <IonIcon icon={IonIcons.codeWorking} slot="start" />
              <IonLabel>
                <h2> {Store.syntaxFilterVariantToString(syntaxFilter)->React.string} </h2>
                <p> {"Syntax Filter"->React.string} </p>
              </IonLabel>
            </IonItem>
            <IonAlert
              trigger="syntax-filter-trigger-alert"
              header="Syntax Filter"
              inputs={State.availableSyntaxFilters->Array.map(f => {
                \"type": #radio,
                label: Store.syntaxFilterVariantToString(f),
                value: Store.syntaxFilterVariantToString(f),
                checked: syntaxFilter == f,
              })}
              buttons={["OK"]}
              onDidDismiss={eventDetail =>
                setSyntaxFilter(Store.syntaxFilterStringToVariant(eventDetail.detail.data.values))}
            />
            <IonItem button={true} id="book-filter-trigger-alert">
              <IonIcon icon={IonIcons.filter} slot="start" />
              <IonLabel>
                <h2> {Store.corpusFilterVariantToString(corpusFilter)->React.string} </h2>
                <p> {"Corpus Filter"->React.string} </p>
              </IonLabel>
            </IonItem>
            <IonAlert
              trigger="book-filter-trigger-alert"
              header="Syntax Filter"
              inputs={State.availableCorpusFilters->Array.map(f => {
                \"type": #radio,
                label: Store.corpusFilterVariantToString(f),
                value: Store.corpusFilterVariantToString(f),
                checked: corpusFilter == f,
              })}
              buttons={["OK"]}
              onDidDismiss={eventDetail =>
                setCorpusFilter(Store.corpusFilterStringToVariant(eventDetail.detail.data.values))}
            />
          </IonItemGroup>
          <IonItemGroup>
            <IonItemDivider>
              <IonLabel> {"Search Terms"->React.string} </IonLabel>
            </IonItemDivider>
            {searchTerms
            ->Array.mapWithIndex((term, i) => {
              <SearchTermItem
                key={term.uuid}
                term={term}
                invertSearchTerm={_ => invertSearchTerm(i)}
                editSearchTerm={_ => ()}
                dropSearchTerm={_ => deleteSearchTerm(i)}
              />
            })
            ->React.array}
          </IonItemGroup>
        </IonList>
      </IonContent>
    </IonPopover>
  }
}

module OrderedResults = {
  @react.component
  let make = (~results, ~visibleModules: array<State.textualEdition>) => {
    let getTextualEditionByIndex = index => visibleModules->Array.get(index)
    <table>
      <thead>
        <tr>
          {visibleModules
          ->Array.map(t => {
            <td
              style={{textAlign: "center", fontWeight: "bold"}}
              key={t.id->Int.toString}
              width={(100 / Array.length(visibleModules))->Int.toString ++ "%"}>
              {t.abbreviation->React.string}
            </td>
          })
          ->React.array}
        </tr>
      </thead>
      <tbody>
        {results
        ->Array.mapWithIndex((row, ri) =>
          [
            <tr key={ri->Int.toString ++ "a"}>
              <td colSpan={row->Array.length} className="search-result-reference">
                {row->getFirstRidForRow->Books.ridToRef->React.string}
              </td>
            </tr>,
            <tr key={ri->Int.toString ++ "b"}>
              {row
              ->Array.mapWithIndex((textualEditionResult, ti) => {
                switch ti->getTextualEditionByIndex {
                | None => "Something went wrong identifying this textualEdition"->React.string
                | Some(t) =>
                  <td
                    key={ti->Int.toString}
                    className="verseText"
                    style={TextObject.getStyleFor(t.abbreviation)}>
                    {textualEditionResult
                    ->Array.mapWithIndex(
                      (v, vi) =>
                        <TextObject.VerseSpan
                          key={vi->Int.toString}
                          textObject={v}
                          textualEditionId={t.id}
                          verseNumber={Some(mod(v.rid, 1000))}
                        />,
                    )
                    ->React.array}
                  </td>
                }
              })
              ->React.array}
            </tr>,
          ]->React.array
        )
        ->React.array}
      </tbody>
    </table>
  }
}

type mode = Ready | Loading | Error

@react.component
let make = () => {
  let ref = React.useRef(Nullable.null)
  let (currentMode, setCurrentMode) = React.useState(_ => Ready)
  let (resultsCount, setResultsCount) = React.useState(_ => 0)
  let (matchingText, setMatchingText) = React.useState(_ => None)
  let (pageNumber, setPageNumber) = React.useState(_ => 0)
  let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
  let setSearchTerms = Store.store->Store.MobileClient.use(state => state.setSearchTerms)
  let serializedSearchTerms = Store.serializeSearchTerms(searchTerms)
  let syntaxFilter = Store.store->Store.MobileClient.use(state => state.syntaxFilter)
  let corpusFilter = Store.store->Store.MobileClient.use(state => state.corpusFilter)
  let textualEditions = Store.store->Store.MobileClient.use(state => state.textualEditions)
  let enabledTextualEditions = textualEditions->Array.filter(m => m.visible)
  let textualEditionAbbreviations =
    enabledTextualEditions
    ->Array.map(m => m.abbreviation)
    ->Array.join(",")
  let (textualEditionsToDisplay, setTextualEditionsToDisplay) = React.useState(_ => [])
  let showSearchResults = Store.store->Store.MobileClient.use(state => state.showSearchResults)
  let setShowSearchResults =
    Store.store->Store.MobileClient.use(state => state.setShowSearchResults)
  let hideSearchResults = () => setShowSearchResults(false)

  React.useEffect(() => {
    setPageNumber(_ => 0)
    None
  }, [serializedSearchTerms])

  React.useEffect5(() => {
    // TODO: make sure that only pagenumber has changed...
    if searchTerms->Array.length === 0 {
      setMatchingText(_ => None)
      setResultsCount(_ => 0)
      setTextualEditionsToDisplay(_ => [])
    } else if searchTerms->Array.length > 0 && textualEditionAbbreviations != "" {
      serializedSearchTerms->Console.log
      setCurrentMode(_ => Loading)
      ignore(
        getSearchResults(
          ~serializedSearchTerms,
          ~syntaxFilter,
          ~corpusFilter,
          ~textualEditionAbbreviations,
          ~pageNumber,
          ~pageSize=pageSizeConstant,
        )->Promise.then(results => {
          switch results {
          | Belt.Result.Error(e) => {
              e->Console.error
              setMatchingText(_ => None)
              setCurrentMode(_ => Error)
            }
          | Belt.Result.Ok(results) => {
              let columnHasData =
                results.matchingText
                ->Array.at(0)
                ->Option.getOr([])
                ->Array.mapWithIndex(
                  (_, i) => {
                    results.matchingText->Array.some(
                      row => row->Array.get(i)->Option.getOr([])->Array.length > 0,
                    )
                  },
                )
              let pluckColumns = (row, columns) =>
                row->Array.filterWithIndex((_, i) => columns[i]->Option.getOr(false))
              let newTextualEditionsToDisplay = pluckColumns(enabledTextualEditions, columnHasData)
              setResultsCount(_ => results.count)
              setTextualEditionsToDisplay(_ => newTextualEditionsToDisplay)
              setMatchingText(
                _ => Some(results.matchingText->Array.map(row => row->pluckColumns(columnHasData))),
              )

              // scroll to top
              switch ref.current {
              | Value(node) => node->WindowBindings.scrollToPoint(~x=0, ~y=0, ~duration=300)
              | Null | Undefined => "Cannot scroll: ref.current is None"->Console.error
              }
              setCurrentMode(_ => Ready)
            }
          }
          Promise.resolve()
        }),
      )
    }
    None
  }, (serializedSearchTerms, syntaxFilter, corpusFilter, textualEditionAbbreviations, pageNumber))

  let totalPages =
    (resultsCount->Int.toFloat /. pageSizeConstant->Int.toFloat)->Js.Math.ceil_int - 1

  <IonModal isOpen={showSearchResults} onDidDismiss={hideSearchResults}>
    <IonHeader>
      <IonToolbar>
        <IonTitle> {`Search Results`->React.string} </IonTitle>
        <IonButtons slot="end">
          <IonButton shape=#round id={"popover-button"}>
            <IonIcon slot="icon-only" icon={IonIcons.ellipsisVertical} />
          </IonButton>
          <SearchMenu />
          <IonButton
            shape=#round
            onClick={() => {
              hideSearchResults()
              setSearchTerms([])
            }}>
            <IonIcon slot="icon-only" icon={IonIcons.trash} />
          </IonButton>
          <IonButton shape=#round onClick={hideSearchResults}>
            <IonIcon slot="icon-only" icon={IonIcons.close} />
          </IonButton>
        </IonButtons>
      </IonToolbar>
    </IonHeader>
    <IonContent ref={ReactDOM.Ref.domRef(ref)} className="ion-padding" scrollX={true}>
      <LoadingIndicator visible={currentMode == Loading} />
      {switch (currentMode, searchTerms->Array.length > 0) {
      | (Error, _) =>
        <CenteredDiv> {"Something has gone horribly wrong"->React.string} </CenteredDiv>
      | (_, false) => <CenteredDiv> {"No search terms"->React.string} </CenteredDiv>
      | (_, true) =>
        switch (matchingText, resultsCount) {
        | (None, _) =>
          <CenteredDiv> {"Something has gone horribly wrong"->React.string} </CenteredDiv>
        | (Some(_), 0) => <CenteredDiv> {"No results"->React.string} </CenteredDiv>
        | (Some(matchingText), _) =>
          <>
            <div className={"result-count"}>
              {`${resultsCount->Int.toString} matches ∙ ${searchTerms
                ->Array.length
                ->Int.toString} search terms`->React.string}
            </div>
            <Pagination
              totalPages={totalPages}
              currentPage={pageNumber}
              setPageNumber={i => setPageNumber(_ => i)}
            />
            <OrderedResults results={matchingText} visibleModules={textualEditionsToDisplay} />
            <Pagination
              totalPages={totalPages}
              currentPage={pageNumber}
              setPageNumber={i => setPageNumber(_ => i)}
            />
          </>
        }
      }}
    </IonContent>
  </IonModal>
}
