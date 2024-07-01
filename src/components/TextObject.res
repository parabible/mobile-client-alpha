type wordObject = {
  wid: int,
  text: string,
  leader: option<string>,
  trailer: option<string>,
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

let decodeWordArray = Json.Decode.array(
  Json.Decode.object(field => {
    wid: field.required("wid", Json.Decode.int),
    text: field.required("text", Json.Decode.string),
    leader: field.optional("leader", Json.Decode.string),
    trailer: field.optional("trailer", Json.Decode.string),
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
    let selectedWord = Zustand.store->Zustand.SomeStore.use(state => {
      state.selectedWord
    })

    let setSelectedWord = Zustand.store->Zustand.SomeStore.use(state => {
      state.setSelectedWord
    })
    let setShowWordInfo = Zustand.store->Zustand.SomeStore.use(state => {
      state.setShowWordInfo
    })
    let onClickHandler = _ => {
      setSelectedWord({
        id: wordPart.wid,
        moduleId: textualEditionId,
      })
      setShowWordInfo(true)
    }

    let style: JsxDOM.style = if (
      selectedWord.id == wordPart.wid && selectedWord.moduleId == textualEditionId
    ) {
      {color: "#0078D7"}
    } else {
      {}
    }

    <>
      {wordPart.leader->Option.getOr("")->React.string}
      <button onClick={onClickHandler} className="word" style={style}>
        {wordPart.text->React.string}
      </button>
      {wordPart.trailer->Option.getOr("")->React.string}
    </>
  }
}

module VerseNumber = {
  @react.component
  let make = (~verseNumber: option<int>) => {
    switch verseNumber {
    | Some(v) => <span className="verseNumber"> {v->Int.toString->React.string} </span>
    | None => <> </>
    }
  }
}

module VerseCell = {
  @react.component
  let make = (
    ~textObject: textObject,
    ~textualEditionId: int,
    ~verseNumber: option<int>,
    ~style: JsxDOM.style,
  ) => {
    switch textObject.\"type" {
    | "html" =>
      <td>
        <VerseNumber verseNumber />
        <span
          style={style} className="verseText" dangerouslySetInnerHTML={{"__html": textObject.html}}
        />
      </td>
    | "wordArray" =>
      <td style={style} className="verseText">
        <VerseNumber verseNumber />
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
    ~style: option<JsxDOM.style>=?,
  ) => {
    switch textObject.\"type" {
    | "html" =>
      <>
        <VerseNumber verseNumber />
        <span
          style={style->Option.getOr({})} dangerouslySetInnerHTML={{"__html": textObject.html}}
        />
      </>
    | "wordArray" =>
      <span style={style->Option.getOr({})}>
        <VerseNumber verseNumber />
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
