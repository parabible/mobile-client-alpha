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
