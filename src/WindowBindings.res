@send
external scrollToPoint: (Dom.element, ~x: int, ~y: int, ~duration: int) => unit = "scrollToPoint"

@scope("crypto") @val
external randomUUID: unit => string = "randomUUID"

// localstorage bindings
module LocalStorage = {
  @scope("localStorage") @val
  external getItemUnsafe: string => Js.Nullable.t<string> = "getItem"

  let getItem = key => key->getItemUnsafe->Js.Nullable.toOption

  @scope("localStorage") @val
  external setItem: (string, string) => unit = "setItem"

  @scope("localStorage") @val
  external removeItem: string => unit = "removeItem"
}

@scope("location") @val external pathname: string = "pathname"

// matchMedia
type matches = {
  media: string,
  matches: bool,
}
@scope("window") @val external matchMedia: string => matches = "matchMedia"

type location = {
  search: string,
  pathname: string,
}
@scope("window") @val external location: location = "location"

type history = {replaceState: (unit, string, string) => unit}
@scope("window") @val external history: history = "history"

module URLSearchParams = {
  type t
  @new @scope("window") external make: string => t = "URLSearchParams"
  @send external get: (t, string) => Js.Nullable.t<string> = "get"
  @send external toString: t => string = "toString"
  external asIterable: t => Js.Array.array_like<(string, string)> = "%identity"
}
