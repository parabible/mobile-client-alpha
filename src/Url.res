module SearchParams = {
  let get = (key: string) => {
    let s = %raw(`(() => {
      const params = window.URLSearchParams ? new URLSearchParams(location.search) : URLSearchParamsPoylfill(location.search)
      return params.get(key)
    })()`)
    s
  }

  let set = (key: string, value: string) => {
    ignore(
      %raw(`(() => {
        const params = new URLSearchParams(location.search)
        params.set(key, value)
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
