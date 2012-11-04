-- an implementation quick sort using comprehensions

items = {4, 5, 2, 1, 3, 8, 9, 0}

-- append array tables
concat = (...) ->
  out = {}
  for t in *{...}
    table.insert out, i for i in *t
  out

format = (t) ->
  print table.concat t, ", "

quicksort = (items) ->
  return {} if #items == 0
  pivot = items[1]
  rest = [i for i in *items[2,]]
  concat quicksort([i for i in *rest when i < pivot ]),
    {pivot},
    quicksort([i for i in *rest when i >= pivot])

format quicksort items

