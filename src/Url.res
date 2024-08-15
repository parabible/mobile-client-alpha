open WindowBindings

module SearchParams = {
  let get = (key: string): string => {
    let params = URLSearchParams.make(location.search)
    params->URLSearchParams.get(key)->Js.Nullable.toOption->Belt.Option.getWithDefault("")
  }

  let getAll = (): array<(string, string)> => {
    let params = URLSearchParams.make(location.search)
    params->URLSearchParams.asIterable->Array.fromArrayLike
  }

  let replace = (params: string): unit => {
    history.replaceState((), "", location.pathname ++ "?" ++ params)
  }
}

module Pathname = {
  let get = (): string => {
    location.pathname->String.sliceToEnd(~start=1)
  }

  let set = (value: string): unit => {
    let params = URLSearchParams.make(location.search)
    history.replaceState((), "", value ++ "?" ++ params->URLSearchParams.toString)
  }
}
