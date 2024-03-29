module Goban
  # Data type representing 2D canvas symbol.
  struct Canvas(T)
    include Indexable::Mutable(T)

    getter size_x : Int32
    getter size_y : Int32
    getter data : Slice(T)

    delegate size, to: @data
    delegate unsafe_fetch, to: @data
    delegate unsafe_put, to: @data

    def initialize(@size_x, @size_y, data : Slice(T))
      @data = data
    end

    def initialize(@size_x, @size_y, value : T)
      @data = Slice.new(@size_x * @size_y, value)
    end

    def clone
      Canvas(T).new(@size_x, @size_y, @data.dup)
    end

    def size
      @size_x
    end

    def each_row(& : Iterator(UInt8), Int32 ->)
      @size_y.times do |y|
        row = @size_x.times.map { |x| self[x, y] }
        yield row, y
      end
    end

    def each_column(& : Iterator(UInt8), Int32 ->)
      @size_x.times do |x|
        column = @size_y.times.map { |y| self[x, y] }
        yield column, x
      end
    end

    @[AlwaysInline]
    def [](x : Int, y : Int)
      raise IndexError.new unless 0 <= x && x < @size_x && 0 <= y && y < @size_y
      @data.unsafe_fetch(y * @size_x + x)
    end

    @[AlwaysInline]
    def []?(x : Int, y : Int)
      return nil unless 0 <= x && x < @size_x && 0 <= y && y < @size_y
      @data.unsafe_fetch(y * @size_x + x)
    end

    @[AlwaysInline]
    def []=(x : Int, y : Int, value : UInt8)
      raise IndexError.new unless 0 <= x && x < @size_x && 0 <= y && y < @size_y
      @data.unsafe_put(y * @size_x + x, value)
    end

    @[AlwaysInline]
    def []=(x : Int, y : Int, w : Int, h : Int, value : UInt8)
      (x...x + w).each do |xx|
        (y...y + h).each do |yy|
          self[xx, yy] = value
        end
      end
    end

    protected def normalize
      @data.map! do |v|
        v & 1
      end
    end

    # Prints the modules on the canvas as a text in the console.
    def print_to_console
      chars = {"  ", "██"}
      each_row do |row|
        row.each do |mod|
          print chars[mod & 1]
        end
        print '\n'
      end
      print '\n'
    end
  end
end
