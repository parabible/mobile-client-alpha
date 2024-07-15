type ionColor = [
  | #primary
  | #secondary
  | #tertiary
  | #success
  | #warning
  | #danger
  | #light
  | #medium
  | #dark
]

module IonicFunctions = {
  @module("@ionic/react") external setupIonicReact: unit => unit = "setupIonicReact"
  type menuController = {\"open": string => unit, close: string => unit}
  @module("@ionic/core/components") external menuController: menuController = "menuController"
}

module IonApp = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonApp"
}

module IonRouterOutlet = {
  @module("@ionic/react") @react.component
  external make: (~id: string, ~children: React.element) => React.element = "IonRouterOutlet"
}

module IonReactRouter = {
  @module("@ionic/react-router") @react.component
  external make: (~children: React.element) => React.element = "IonReactRouter"
}

module Route = {
  @module("react-router-dom") @react.component
  external make: (~path: string, ~exact: bool, ~children: React.element) => React.element = "Route"
}

module Redirect = {
  @module("react-router-dom") @react.component
  external make: (~to: string) => React.element = "Redirect"
}

module IonPage = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonPage"
}

module IonHeader = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonHeader"
}

module IonContent = {
  @module("@ionic/react") @react.component
  external make: (
    ~className: string=?,
    ~fullscreen: bool=?,
    ~scrollX: bool=?,
    ~children: React.element,
    ~ref: ReactDOM.Ref.t=?,
  ) => React.element = "IonContent"
}

module IonToolbar = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonToolbar"
}

module IonTitle = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonTitle"
}

module IonMenu = {
  @module("@ionic/react") @react.component
  external make: (
    ~menuId: string,
    ~side: string,
    ~contentId: string,
    ~\"type": string,
    ~ionDidClose: unit => unit=?,
    ~children: React.element,
  ) => React.element = "IonMenu"
}

module IonSearchbar = {
  @module("@ionic/react") @react.component
  external make: (~onIonInput: ReactEvent.Form.t => unit) => React.element = "IonSearchbar"
}

module IonList = {
  type lines = [#none | #full | #inset]
  @module("@ionic/react") @react.component
  external make: (~lines: lines=?, ~inset: bool=?, ~children: React.element) => React.element =
    "IonList"
}

module IonListHeader = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonListHeader"
}

module IonReorderGroup = {
  type eventDetail = {
    from: int,
    to: int,
    complete: unit => unit,
  }
  type event = {detail: eventDetail}
  @module("@ionic/react") @react.component
  external make: (
    ~disabled: bool,
    ~onIonItemReorder: event => unit,
    ~children: React.element,
  ) => React.element = "IonReorderGroup"
}

module IonItem = {
  @module("@ionic/react") @react.component
  external make: (
    ~id: string=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~button: bool=?,
    ~detail: bool=?,
    ~children: React.element,
  ) => React.element = "IonItem"
}

module IonCheckbox = {
  @module("@ionic/react") @react.component
  external make: (
    ~labelPlacement: [#start | #end]=?,
    ~justify: string=?,
    ~checked: bool=?,
    ~onIonChange: ReactEvent.Form.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "IonCheckbox"
}

module IonReorder = {
  @module("@ionic/react") @react.component
  external make: (~slot: string) => React.element = "IonReorder"
}

module IonButtons = {
  @module("@ionic/react") @react.component
  external make: (~slot: string, ~children: React.element) => React.element = "IonButtons"
}

module IonIcon = {
  @module("@ionic/react") @react.component
  external make: (~slot: string=?, ~icon: React.element=?, ~src: string=?) => React.element =
    "IonIcon"
}

module IonLabel = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonLabel"
}

type buttonExpand = [#block | #full]
type buttonFill = [#clear | #outline | #solid]
type buttonSize = [#small | #default | #large]
type buttonShape = [#round]
module IonButton = {
  @module("@ionic/react") @react.component
  external make: (
    ~id: string=?,
    ~color: ionColor=?,
    ~disabled: bool=?,
    ~onClick: unit => unit=?,
    ~expand: buttonExpand=?,
    ~shape: buttonShape=?,
    ~size: buttonSize=?,
    ~fill: buttonFill=?,
    ~style: ReactDOM.Style.t=?,
    ~children: React.element=?,
  ) => React.element = "IonButton"
}

module IonModal = {
  @module("@ionic/react") @react.component
  external make: (
    ~isOpen: bool,
    ~className: string=?,
    ~initialBreakpoint: float=?,
    ~breakpoints: array<float>=?,
    ~onDidDismiss: unit => unit=?,
    ~children: React.element=?,
  ) => React.element = "IonModal"
}

module IonItemGroup = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonItemGroup"
}

module IonItemDivider = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonItemDivider"
}

// type alertButtonInterface = {
//   text: string,
//   role?: string,
//   id?: string,
//   handler?: unit => unit,
// }
type eventDetail = {values: string}
type eventData = {data: eventDetail}
type alertDismissEvent = {detail: eventData}
type alertInputType = [#text | #checkbox | #radio | #textarea]
type alertInput = {
  \"type"?: alertInputType,
  name?: string,
  placeholder?: string,
  value?: string,
  label?: string,
  checked?: bool,
  disabled?: bool,
}
module IonAlert = {
  @module("@ionic/react") @react.component
  external make: (
    ~trigger: string=?,
    ~header: string=?,
    ~subHeader: string=?,
    ~message: string=?,
    // ~buttons: array<alertButtonInterface>=?,
    ~buttons: array<string>=?,
    ~inputs: array<alertInput>=?,
    ~onDidDismiss: alertDismissEvent => unit=?,
  ) => React.element = "IonAlert"
}

module IonPopover = {
  type popoverAlignment = [#center | #start | #end]
  type popoverSide = [#top | #bottom | #start | #end | #left | #right]
  @module("@ionic/react") @react.component
  external make: (
    ~trigger: string,
    ~dismissOnSelect: bool=?,
    ~side: popoverSide=?,
    ~alignment: popoverAlignment=?,
    ~children: React.element,
  ) => React.element = "IonPopover"
}

module IonSpinner = {
  type spinnerName = [
    | #bubbles
    | #circles
    | #circular
    | #crescent
    | #dots
    | #lines
    | #linesSharp
    | #linesSharpSmall
    | #linesSmall
  ]
  @module("@ionic/react") @react.component
  external make: (~name: spinnerName=?, ~color: ionColor=?) => React.element = "IonSpinner"
}

module IonItemOption = {
  @module("@ionic/react") @react.component
  external make: (
    ~color: ionColor=?,
    ~onClick: unit => unit=?,
    ~expandable: bool=?,
    ~children: React.element,
  ) => React.element = "IonItemOption"
}

module IonItemOptions = {
  type optionsSlot = [#start | #end]
  @module("@ionic/react") @react.component
  external make: (~side: optionsSlot=?, ~children: React.element) => React.element =
    "IonItemOptions"
}

module IonItemSliding = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonItemSliding"
}

module IonRadioGroup = {
  type eventDetail = {value: string}
  type event = {detail: eventDetail}
  @module("@ionic/react") @react.component
  external make: (
    ~value: string,
    ~onIonChange: event => unit=?,
    ~children: React.element,
  ) => React.element = "IonRadioGroup"
}

module IonRadio = {
  @module("@ionic/react") @react.component
  external make: (~key: string, ~value: string, ~children: React.element) => React.element =
    "IonRadio"
}

module IonProgressBar = {
  type progressBarType = [#determinate | #indeterminate]
  @module("@ionic/react") @react.component
  external make: (~\"type": progressBarType, ~color: ionColor=?, ~value: float=?) => React.element =
    "IonProgressBar"
}

module IonIcons = {
  @module("ionicons/icons") external library: React.element = "library"
  @module("ionicons/icons") external settings: React.element = "settings"
  @module("ionicons/icons") external apps: React.element = "apps"
  @module("ionicons/icons") external search: React.element = "search"
  @module("ionicons/icons") external close: React.element = "close"
  @module("ionicons/icons") external chevronBackOutline: React.element = "chevronBackOutline"
  @module("ionicons/icons") external chevronForward: React.element = "chevronForward"
  @module("ionicons/icons") external chevronBack: React.element = "chevronBack"
  @module("ionicons/icons") external caretForward: React.element = "caretForward"
  @module("ionicons/icons") external caretBack: React.element = "caretBack"
  @module("ionicons/icons") external playForward: React.element = "playForward"
  @module("ionicons/icons") external playBack: React.element = "playBack"
  @module("ionicons/icons") external ellipsisVertical: React.element = "ellipsisVertical"
  @module("ionicons/icons") external filter: React.element = "filter"
  @module("ionicons/icons") external codeWorking: React.element = "codeWorking"
  @module("ionicons/icons") external trash: React.element = "trash"
  @module("ionicons/icons") external options: React.element = "options"
  @module("ionicons/icons") external power: React.element = "power"
  @module("ionicons/icons") external flash: React.element = "flash"
  @module("ionicons/icons") external flashOff: React.element = "flashOff"
}
