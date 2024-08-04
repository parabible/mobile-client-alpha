type textualEdition = {id: int, abbreviation: string, visible: bool}

type searchTermDataPoint = {key: string, value: string}

type searchTerm = {
  uuid: string,
  inverted: bool,
  data: array<searchTermDataPoint>,
}

let serializeSearchTerms = (searchTerms: array<searchTerm>) =>
  searchTerms
  ->Array.mapWithIndex((term, i) =>
    [
      ...term.data->Array.map(datapoint =>
        ["t", i->Int.toString, "data", datapoint.key ++ "=" ++ datapoint.value]->Array.join(".")
      ),
      ["t", i->Int.toString, "inverted" ++ "=" ++ term.inverted->String.make]->Array.join("."),
    ]->Array.join("&")
  )
  ->Array.join("&")

// t.0.data.lexeme=σκοτία&t.0.inverted=false
type validParam = DataPoint | Inversion | Invalid

type validParamData = {
  index: int,
  key: string,
  value: string,
  inverted: bool,
  type_: validParam,
}

let deserializeInversionData = d => {
  switch d {
  | "false" => false
  | "true" => true
  | _ => false
  }
}

let deserializeParam = (paramKey, paramValue) => {
  let parts = paramKey->String.split(".")
  // parts[0] != "t" => None
  let t = switch parts->Array.get(0) {
  | Some(t) => t == "t"
  | None => false
  }
  let index = switch parts->Array.get(1) {
  | Some(i) => i->Int.fromString
  | None => None
  }
  // parts[2] != "data" | "inverted" => None
  let type_ = switch parts->Array.get(2) {
  | Some(t) =>
    switch t {
    | "data" => DataPoint
    | "inverted" => Inversion
    | _ => Invalid
    }
  | None => Invalid
  }
  let d = parts->Array.get(3)

  switch (t, index, type_, d) {
  | (false, _, _, _)
  | (_, None, _, _)
  | (_, _, Invalid, _)
  | (_, _, _, None) =>
    None
  | (true, Some(index), DataPoint, Some(key)) =>
    Some({
      index,
      key,
      value: paramValue,
      type_: DataPoint,
      inverted: false,
    })
  | (true, Some(index), Inversion, Some(inverted)) =>
    Some({
      index,
      key: "",
      value: "",
      type_: Inversion,
      inverted: deserializeInversionData(inverted),
    })
  }
}

let convertValidDataPointsToSearchTerms = (dataPoints: array<validParamData>) => {
  let searchTerms = []
  dataPoints->Array.forEach(dataPoint => {
    switch dataPoint.type_ {
    | Invalid => ()
    | DataPoint =>
      let searchTerm = searchTerms->Array.get(dataPoint.index)
      switch searchTerm {
      | Some(searchTerm) =>
        searchTerms->Array.set(
          dataPoint.index,
          {
            ...searchTerm,
            data: [...searchTerm.data, {key: dataPoint.key, value: dataPoint.value}],
          },
        )
      | None =>
        searchTerms->Array.push({
          uuid: WindowBindings.randomUUID(),
          inverted: false,
          data: [{key: dataPoint.key, value: dataPoint.value}],
        })
      }
    | Inversion =>
      let searchTerm = searchTerms->Array.get(dataPoint.index)
      switch searchTerm {
      | Some(searchTerm) =>
        searchTerms->Array.set(
          dataPoint.index,
          {
            ...searchTerm,
            inverted: dataPoint.inverted,
          },
        )
      | None =>
        searchTerms->Array.push({
          uuid: WindowBindings.randomUUID(),
          inverted: dataPoint.inverted,
          data: [],
        })
      }
    }
  })
  searchTerms
}

let deserializeSearchTermParams = params =>
  params
  ->Array.map(((key, value)) => {
    deserializeParam(key, value)
  })
  ->Array.filterMap(x => x)
  ->convertValidDataPointsToSearchTerms
