module IonicFunctions = {
  @module("@ionic/react") external setupIonicReact: unit => unit = "setupIonicReact"
  type menuController = {\"open": string => unit}
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
  external make: (~lines: lines=?, ~inset: bool=?, ~children: React.element) => React.element = "IonList"
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
  external make: (~children: React.element) => React.element = "IonItem"
}

module IonCheckbox = {
  @module("@ionic/react") @react.component
  external make: (
    ~labelPlacement: [#start | #end],
    ~justify: string,
    ~checked: bool,
    ~onIonChange: unit => unit,
    ~children: React.element,
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
  external make: (~slot: string, ~icon: React.element) => React.element = "IonIcon"
}

module IonLabel = {
  @module("@ionic/react") @react.component
  external make: (~children: React.element) => React.element = "IonLabel"
}

type buttonExpand = [#block | #full]
type buttonFill = [#clear | #outline | #solid]
module IonButton = {
  @module("@ionic/react") @react.component
  external make: (
    ~color: string=?,
    ~onClick: unit => unit=?,
    ~expand: buttonExpand=?,
    ~shape: string=?,
    ~fill: buttonFill=?,
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

module IonIcons = {
  @module("ionicons/icons") external library: React.element = "library"
  @module("ionicons/icons") external settings: React.element = "settings"
  @module("ionicons/icons") external apps: React.element = "apps"
  @module("ionicons/icons") external search: React.element = "search"
  @module("ionicons/icons") external close: React.element = "close"
}
