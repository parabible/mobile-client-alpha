// type state = {
//   count: int,
//   increment: unit => unit,
//   decrement: unit => unit,
// };

// let store = Zustand.create((set: (state => state)) => {
//   let updateCount = (fn: int => int) => set(s => {
//     {...s, count: fn(s.count)}
//   });

//   {
//     count: 0,
//     increment: () => updateCount(x => x + 1),
//     decrement: () => updateCount(x => x - 1),
//   }
// });