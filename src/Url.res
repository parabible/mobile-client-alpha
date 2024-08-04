module SearchParams = {
  let get = (key: string) => {
    let s = %raw(`(() => {
      const params = new URLSearchParams(location.search)
      return params.get(key) || ""
    })()`)
    s
  }

  let getAll = () => {
    let s = %raw(`(() => {
      const params = new URLSearchParams(location.search)
      return Array.from(params)
    })()`)
    s
  }

  // let set = (key: string, value: string) => {
  //   ignore(
  //     %raw(`(() => {
  //       const params = new URLSearchParams(location.search)
  //       params.set(key, value)
  //       window.history.replaceState({}, '', location.pathname + "?" + params)
  //     })()`),
  //   )
  // }

  let replace = (params: string) => {
    ignore(
      %raw(`(() => {
        window.history.replaceState({}, '', location.pathname + "?" + params)
      })()`),
    )
  }
}

module Pathname = {
  let get = () => {
    // First char is a "/"
    WindowBindings.pathname->String.sliceToEnd(~start=1)
  }
  let set = (value: string) => {
    ignore(
      %raw(`(() => {
        const params = new URLSearchParams(location.search)
        window.history.replaceState({}, '', value + "?" + params)
      })()`),
    )
  }
}
