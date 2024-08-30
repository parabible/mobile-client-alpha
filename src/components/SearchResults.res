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
  ~currentReference: Books.reference,
  ~pageNumber,
  ~pageSize,
) => {
  let modules = `modules=${textualEditionAbbreviations}`
  let syntaxFilter = `treeNodeType=${State.syntaxFilterToTreeNodeTypeString(syntaxFilter)}`
  let corpusFilter = switch corpusFilter {
  | None => ""
  | corpusFilter => `corpusFilter=${State.corpusToReferenceString(corpusFilter, currentReference)}`
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
  ~currentReference,
  ~textualEditionAbbreviations,
  ~pageNumber,
  ~pageSize,
) => {
  let url = getUrl(
    ~serializedSearchTerms,
    ~textualEditionAbbreviations,
    ~syntaxFilter,
    ~corpusFilter,
    ~currentReference,
    ~pageNumber,
    ~pageSize,
  )
  let response = await Fetch.fetch(url, {method: #GET})
  let json = await response->Fetch.Response.json
  json->Json.decode(decodeTermSearchResult)
}

let getFirstRidForRow = (row: resultRow) =>
  row
  ->Array.reduce(None, (acc, teMatch) =>
    switch (acc, teMatch->Array.at(0)) {
    | (None, Some(textObject)) => Some(textObject.rid)
    | (_, _) => acc
    }
  )
  ->Option.getOr(0)

module CenteredDiv = {
  @react.component
  let make = (~children, ~className="") => {
    <div className={"centered " ++ className}> {children} </div>
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
  let make = (
    ~term: SearchTermSerde.searchTerm,
    ~invertSearchTerm,
    ~editSearchTerm,
    ~dropSearchTerm,
  ) => {
    <IonItemSliding>
      <IonItem detail={true}>
        <IonLabel>
          <h2> {term->State.searchTermToFriendlyString->React.string} </h2>
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

module FilterOptionsMenu = {
  @react.component
  let make = () => {
    let syntaxFilter = Store.store->Store.MobileClient.use(state => state.syntaxFilter)
    let setSyntaxFilter = Store.store->Store.MobileClient.use(state => state.setSyntaxFilter)
    let corpusFilter = Store.store->Store.MobileClient.use(state => state.corpusFilter)
    let setCorpusFilter = Store.store->Store.MobileClient.use(state => state.setCorpusFilter)
    <IonPopover trigger="filter-options-menu" dismissOnSelect={false}>
      <IonContent>
        <IonList>
          <IonItem button={true} id="syntax-filter-trigger-alert">
            <IonIcon icon={IonIcons.codeWorking} slot="start" />
            <IonLabel>
              <h2> {State.syntaxFilterVariantToString(syntaxFilter)->React.string} </h2>
              <p> {"Syntax Filter"->React.string} </p>
            </IonLabel>
          </IonItem>
          <IonAlert
            trigger="syntax-filter-trigger-alert"
            header="Syntax Filter"
            inputs={State.availableSyntaxFilters->Array.map(f => {
              \"type": #radio,
              label: State.syntaxFilterVariantToString(f),
              value: State.syntaxFilterVariantToString(f),
              checked: syntaxFilter == f,
            })}
            buttons={["OK"]}
            onDidDismiss={eventDetail =>
              setSyntaxFilter(State.syntaxFilterStringToVariant(eventDetail.detail.data.values))}
          />
          <IonItem button={true} id="book-filter-trigger-alert">
            <IonIcon icon={IonIcons.filterCircleOutline} slot="start" />
            <IonLabel>
              <h2> {State.corpusFilterVariantToString(corpusFilter)->React.string} </h2>
              <p> {"Corpus Filter"->React.string} </p>
            </IonLabel>
          </IonItem>
          <IonAlert
            trigger="book-filter-trigger-alert"
            header="Corpus Filter"
            inputs={State.availableCorpusFilters->Array.map(f => {
              \"type": #radio,
              label: State.corpusFilterVariantToString(f),
              value: State.corpusFilterVariantToString(f),
              checked: corpusFilter == f,
            })}
            buttons={["OK"]}
            onDidDismiss={eventDetail =>
              setCorpusFilter(State.corpusFilterStringToVariant(eventDetail.detail.data.values))}
          />
        </IonList>
      </IonContent>
    </IonPopover>
  }
}

module SearchTermMenu = {
  @react.component
  let make = () => {
    let searchTerms = Store.store->Store.MobileClient.use(state => state.searchTerms)
    let deleteSearchTerm = Store.store->Store.MobileClient.use(state => state.deleteSearchTerm)
    let setSearchTerms = Store.store->Store.MobileClient.use(state => state.setSearchTerms)
    let invertSearchTerm = index =>
      setSearchTerms(
        searchTerms->Array.mapWithIndex((term, i) => {
          if i == index {
            let term: SearchTermSerde.searchTerm = {
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
    <IonPopover trigger="search-term-menu" dismissOnSelect={false}>
      <IonContent>
        <IonList>
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
          <IonItemGroup>
            <IonItemDivider>
              <IonLabel> {"Options"->React.string} </IonLabel>
            </IonItemDivider>
            <IonItem
              button={true}
              onClick={_ => {
                setSearchTerms([])
              }}>
              <IonIcon color={#danger} icon={IonIcons.trashOutline} slot="end" />
              <IonLabel> {"Clear search terms"->React.string} </IonLabel>
            </IonItem>
          </IonItemGroup>
        </IonList>
      </IonContent>
    </IonPopover>
  }
}

module OrderedResults = {
  let splitByCorpus = results => {
    let corpora =
      results
      ->Array.map(row => {
        let rid = row->getFirstRidForRow
        let reference = rid->Books.ridToBookChapterReference
        reference->ReferenceParser.getCorpusFromReference
      })
      ->Set.fromArray
      ->Set.values
      ->Array.fromIterator
    corpora->Array.map(corpus =>
      results->Array.filter(row => {
        let rid = row->getFirstRidForRow
        let reference = rid->Books.ridToBookChapterReference
        let corpusFromReference = reference->ReferenceParser.getCorpusFromReference
        corpusFromReference == corpus
      })
    )
  }
  @react.component
  let make = (~results, ~visibleModules: array<State.textualEdition>) => {
    let getTextualEditionByIndex = index => visibleModules->Array.get(index)

    results
    ->splitByCorpus
    ->Array.mapWithIndex((corpusResults, corpusIndex) => {
      let columnHasData =
        corpusResults
        ->Array.at(0)
        ->Option.getOr([])
        ->Array.mapWithIndex((_, i) => {
          let onlyColumnI: array<option<teMatch>> = corpusResults->Array.map(row => row[i])
          onlyColumnI->Array.some(t => t->Option.getOr([])->Array.length > 0)
        })
      let textualEditionsForCorpus =
        visibleModules->Array.filterWithIndex((_, i) => columnHasData[i]->Option.getOr(false))

      <>
        {corpusIndex > 0 ? <hr className="my-8 mx-8 h-px border-t-0 divider" /> : <> </>}
        <table key={corpusIndex->Int.toString}>
          <thead>
            <tr>
              {textualEditionsForCorpus
              ->Array.map(t => {
                <td
                  style={{textAlign: "center", fontWeight: "bold"}}
                  key={t.id->Int.toString}
                  width={(100 / Array.length(textualEditionsForCorpus))->Int.toString ++ "%"}>
                  {t.abbreviation->React.string}
                </td>
              })
              ->React.array}
            </tr>
          </thead>
          <tbody>
            {corpusResults
            ->Array.mapWithIndex((row, ri) =>
              [
                <tr key={ri->Int.toString ++ "a"}>
                  <td colSpan={row->Array.length} className="search-result-reference">
                    {row->getFirstRidForRow->Books.ridToReferenceString->React.string}
                  </td>
                </tr>,
                <tr key={ri->Int.toString ++ "b"}>
                  {row
                  ->Array.filterWithIndex((_, i) => columnHasData[i]->Option.getOr(false))
                  ->Array.mapWithIndex(
                    (textualEditionResult, ti) => {
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
                    },
                  )
                  ->React.array}
                </tr>,
              ]->React.array
            )
            ->React.array}
          </tbody>
        </table>
      </>
    })
    ->React.array
  }
}

module NoResults = {
  @react.component
  let make = () => {
    let (showSuggestions, setShowSuggestions) = React.useState(_ => false)
    let onDismissSuggestions = () => setShowSuggestions(_ => false)

    <CenteredDiv className="flex-col">
      <NoResultsHelper show={showSuggestions} onDismiss={onDismissSuggestions} />
      <div className="text-xl flex flex-col items-center">
        <div className="no-results-icon">
          <IonIcon icon={IonIcons.search} />
        </div>
      </div>
      <div className="mt-4 mb-8 text-xl font-bold text-gray-500">
        {"No results match your query"->React.string}
      </div>
      <IonButton shape={#round} onClick={_ => setShowSuggestions(_ => true)}>
        {"Suggestions"->React.string}
      </IonButton>
    </CenteredDiv>
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
  let reference = Store.store->Store.MobileClient.use(state => state.reference)
  let serializedSearchTerms = SearchTermSerde.serializeSearchTerms(
    (searchTerms :> array<SearchTermSerde.searchTerm>),
  )
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

  React.useEffect6(() => {
    // TODO: make sure that only pagenumber has changed...
    if searchTerms->Array.length === 0 {
      setMatchingText(_ => None)
      setResultsCount(_ => 0)
      setTextualEditionsToDisplay(_ => [])
    } else if searchTerms->Array.length > 0 && textualEditionAbbreviations != "" {
      setCurrentMode(_ => Loading)
      ignore(
        getSearchResults(
          ~serializedSearchTerms,
          ~syntaxFilter,
          ~corpusFilter,
          ~currentReference=reference,
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
  }, (
    serializedSearchTerms,
    syntaxFilter,
    corpusFilter,
    reference,
    textualEditionAbbreviations,
    pageNumber,
  ))

  let totalPages =
    (resultsCount->Int.toFloat /. pageSizeConstant->Int.toFloat)->Js.Math.ceil_int - 1

  if totalPages >= 0 && pageNumber > totalPages {
    setPageNumber(_ => totalPages)
  }

  <IonModal
    isOpen={showSearchResults} onDidDismiss={hideSearchResults} className="fullscreen-modal">
    <IonHeader>
      <IonToolbar color={#light}>
        <IonButtons slot="start">
          <IonButton shape=#round onClick={hideSearchResults}>
            <IonIcon slot="icon-only" icon={IonIcons.arrowBack} />
          </IonButton>
        </IonButtons>
        <IonTitle> {`Search Results`->React.string} </IonTitle>
        <IonButtons slot="end">
          <IonButton shape=#round id={"search-term-menu"}>
            <IonIcon slot="icon-only" icon={IonIcons.extensionPuzzleOutline} />
          </IonButton>
          <SearchTermMenu />
          <IonButton shape=#round id={"filter-options-menu"}>
            <IonIcon slot="icon-only" icon={IonIcons.filter} />
          </IonButton>
          <FilterOptionsMenu />
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
        | (Some(_), 0) => <NoResults />
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
