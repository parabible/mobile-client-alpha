type wordTemperature = Cold | Warm | Hot

type wordObject = {
  wid: int,
  text: string,
  leader: option<string>,
  trailer: option<string>,
  temp: option<wordTemperature>,
}

type wordArray = array<wordObject>

type textObject = {
  parallelId: int,
  textualEditionId: int,
  rid: int,
  \"type": string, // We need to force type to only be "html" or "wordArray"
  html: string,
  wordArray: wordArray,
}

let decodeTemp = Json.Decode.custom(value =>
  switch value {
  | String("") => Cold
  | String("warm") => Warm
  | String("hot") => Hot
  | _ => Cold
  }
)

let decodeWordArray = Json.Decode.array(
  Json.Decode.object(field => {
    wid: field.required("wid", Json.Decode.int),
    text: field.required("text", Json.Decode.string),
    leader: field.optional("leader", Json.Decode.string),
    trailer: field.optional("trailer", Json.Decode.string),
    temp: field.optional("temp", decodeTemp),
  }),
)

let decodeTextObject = Json.Decode.object(field => {
  parallelId: field.required("parallelId", Json.Decode.int),
  textualEditionId: field.required("moduleId", Json.Decode.int),
  rid: field.required("rid", Json.Decode.int),
  \"type": field.required("type", Json.Decode.string),
  html: field.required("html", Json.Decode.string),
  wordArray: field.required("wordArray", decodeWordArray),
})

let decodeTextResult = Json.Decode.array(Json.Decode.array(Json.Decode.option(decodeTextObject)))

let getStyleFor: string => JsxDOM.style = (abbr: string) =>
  switch abbr {
  | "BHSA" => {fontFamily: "SBL BibLit", fontSize: "1.4rem", direction: "rtl"}
  | "LXXR" => {fontFamily: "SBL BibLit", fontSize: "1.2rem"}
  | "NA1904" => {fontFamily: "SBL BibLit", fontSize: "1.2rem"}
  | "APF" => {fontFamily: "SBL BibLit", fontSize: "1.2rem"}
  | _ => {fontSize: "1rem"}
  }

module WordNode = {
  @react.component
  let make = (~wordPart: wordObject, ~textualEditionId: int) => {
    let selectedWord = Store.store->Store.MobileClient.use(state => {
      state.selectedWord
    })

    let setSelectedWord = Store.store->Store.MobileClient.use(state => {
      state.setSelectedWord
    })
    let setShowWordInfo = Store.store->Store.MobileClient.use(state => {
      state.setShowWordInfo
    })
    let onClickHandler = _ => {
      setSelectedWord({
        id: wordPart.wid,
        moduleId: textualEditionId,
      })
      setShowWordInfo(true)
    }

    let isSelecterd = selectedWord.id == wordPart.wid && selectedWord.moduleId == textualEditionId
    let style: JsxDOM.style = switch (isSelecterd, wordPart.temp) {
    | (true, _) => {color: "var(--ion-color-primary)"}
    | (false, Some(Hot)) => {color: "var(--ion-color-danger)"}
    | (false, Some(Warm)) => {color: "var(--ion-color-warning)"}
    | (false, _) => {}
    }

    <>
      {wordPart.leader->Option.getOr("")->React.string}
      <span onClick={onClickHandler} className="word" style={style}>
        {wordPart.text->React.string}
      </span>
      {wordPart.trailer->Option.getOr("")->React.string}
    </>
  }
}

module VerseNumber = {
  @react.component
  let make = (
    ~verseNumber: option<int>,
    ~chapterNumber: option<int>,
    ~expectedVerse: option<int>,
    ~expectedChapter: option<int>,
  ) => {
    switch (verseNumber, chapterNumber, expectedVerse, expectedChapter) {
    | (None, _, _, _) => <> </>
    | (Some(v), Some(c), Some(ev), Some(ec)) =>
      if c != ec {
        <span className="verseNumber highlightChapterDifference">
          {(c->Int.toString ++ ":" ++ v->Int.toString)->React.string}
        </span>
      } else if v != ev {
        <span className="verseNumber highlightVerseDifference">
          {v->Int.toString->React.string}
        </span>
      } else {
        <span className="verseNumber"> {v->Int.toString->React.string} </span>
      }
    | (Some(v), _, Some(ev), _) =>
      if v != ev {
        <span className="verseNumber highlightVerseDifference">
          {v->Int.toString->React.string}
        </span>
      } else {
        <span className="verseNumber"> {v->Int.toString->React.string} </span>
      }
    | (Some(v), _, _, _) => <span className="verseNumber"> {v->Int.toString->React.string} </span>
    }
  }
}

module VerseCell = {
  @react.component
  let make = (
    ~textObject: textObject,
    ~textualEditionId: int,
    ~verseNumber: option<int>,
    ~chapterNumber: option<int>,
    ~expectedChapter: option<int>,
    ~expectedVerse: option<int>,
    ~style: JsxDOM.style,
  ) => {
    switch textObject.\"type" {
    | "html" =>
      <td>
        <VerseNumber verseNumber chapterNumber expectedChapter expectedVerse />
        <span
          style={style} className="verseText" dangerouslySetInnerHTML={{"__html": textObject.html}}
        />
      </td>
    | "wordArray" =>
      <td style={style} className="verseText">
        <VerseNumber verseNumber chapterNumber expectedChapter expectedVerse />
        {textObject.wordArray
        ->Array.mapWithIndex((w, i) => {
          <WordNode key={i->Int.toString} wordPart={w} textualEditionId={textualEditionId} />
        })
        ->React.array}
      </td>
    | _ => {
        "Unknown type found in textObject"->Console.error
        <td />
      }
    }
  }
}
module VerseSpan = {
  @react.component
  let make = (
    ~textObject: textObject,
    ~textualEditionId: int,
    ~verseNumber: option<int>,
    ~chapterNumber: option<int>,
    ~expectedChapter: option<int>,
    ~expectedVerse: option<int>,
    ~style: option<JsxDOM.style>=?,
  ) => {
    switch textObject.\"type" {
    | "html" =>
      <>
        <VerseNumber verseNumber chapterNumber expectedVerse expectedChapter />
        <span
          style={style->Option.getOr({})} dangerouslySetInnerHTML={{"__html": textObject.html}}
        />
      </>
    | "wordArray" =>
      <span style={style->Option.getOr({})}>
        <VerseNumber verseNumber chapterNumber expectedVerse expectedChapter />
        {textObject.wordArray
        ->Array.mapWithIndex((w, i) => {
          <WordNode key={i->Int.toString} wordPart={w} textualEditionId={textualEditionId} />
        })
        ->React.array}
      </span>
    | _ => {
        "Unknown type found in textObject"->Console.error
        <span />
      }
    }
  }
}
