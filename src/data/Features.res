type feature = {
  key: string,
  value: string,
  enum: bool,
}

type value = {
  feature: string,
  key: string,
  value: string,
}

type featuresFile = {
  features: array<feature>,
  values: array<value>,
}

@module external featuresFile: Js.Json.t = "./features.json"

let featuresList = featuresFile->Json.decode(
  Json.Decode.object(field => {
    features: field.required(
      "features",
      Json.Decode.array(
        Json.Decode.object(field => {
          key: field.required("key", Json.Decode.string),
          value: field.required("value", Json.Decode.string),
          enum: field.required("enum", Json.Decode.bool),
        }),
      ),
    ),
    values: field.required(
      "values",
      Json.Decode.array(
        Json.Decode.object(field => {
          feature: field.required("feature", Json.Decode.string),
          key: field.required("key", Json.Decode.string),
          value: field.required("value", Json.Decode.string),
        }),
      ),
    ),
  }),
)

let features = switch featuresList {
| Belt.Result.Ok(f) => f.features
| Belt.Result.Error(_) => []
}

let values = switch featuresList {
| Belt.Result.Ok(f) => f.values
| Belt.Result.Error(_) => []
}

let getFeatureName = (key: string) =>
  switch features->Array.find(f => f.key == key) {
  | Some(f) => f.value
  | None => key
  }

let getFeatureValue = (feature: string, key: string) =>
  switch values->Array.find(v => v.feature == feature && v.key == key) {
  | Some(v) => v.value
  | None => key
  }
