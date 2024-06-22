// type fetchingChapterState = IDLE | PENDING | SUCCESS | FAILURE

// type state = {
//   currentBook: string,
//   currentChapter: string,
//   activeWordId: int,
//   activeModuleId: int,
//   fetchingChapterState: fetchingChapterState,
//   setCurrentBook: string => unit,
// }

// let context = React.createContext({
//   currentBook: "Genesis",
//   currentChapter: "1",
//   activeWordId: -1,
//   activeModuleId: -1,
//   fetchingChapterState: IDLE,
//   setCurrentBook: _ => (),
// })

// let setCurrentBook = book => {
//   context.set(state => {...state, currentBook: book})
// }

// let initialState = {
//   currentBook: "Genesis",
//   currentChapter: "1",
//   activeWordId: -1,
//   activeModuleId: -1,
//   fetchingChapterState: IDLE,
//   setCurrentBook: setCurrentBook,
// }


// module Provider = {
//   let make = React.Context.provider(context)
// }
