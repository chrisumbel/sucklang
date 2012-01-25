
class InventoryItem
  # method
  def tax
    @price * 0.07
  end
end

class Movie < InventoryItem
  attr_reader :title

  # constructor
  def initialize(title, price)
    @title, @price = title, price
  end
end

movie = Movie.new("The Day the Earth Stood Still", 9.99)
puts movie.title
puts movie.tax


