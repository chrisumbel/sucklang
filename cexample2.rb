
pairs = {
  "one" => 1,
  "two" => 2
}

pairs["three"] = 3
puts pairs["two"]

pairs = {
  :one => 1,
  :two => 2
}

pairs[:three] = 3
puts pairs[:two]

numbers = [1, 2]
numbers << 3
puts numbers.inspect
