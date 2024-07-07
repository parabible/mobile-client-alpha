@send
external scrollToPoint: (Dom.element, ~x: int, ~y: int, ~duration: int) => unit = "scrollToPoint"

@scope("crypto") @val
external randomUUID: unit => string = "randomUUID"
