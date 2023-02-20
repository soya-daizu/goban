module Goban
  # Holds information about each modules in a QR Code symbol.
  struct Canvas
    # Returns the array of modules drawn on the canvas.
    getter modules : Slice(UInt8)
    # Horizontal length of the canvas.
    getter size_x : Int32
    # Vertical length of the canvas.
    getter size_y : Int32

    protected def initialize(@size_x, size_y : Int? = nil, modules : Slice(UInt8)? = nil)
      @size_y = size_y || @size_x
      @modules = modules || Slice(UInt8).new(@size_x * @size_y)
    end

    def clone
      Canvas.new(@size_x, @size_y, @modules.dup)
    end

    def size
      @size_x
    end

    def each_row(& : Slice(UInt8), Int32 ->)
      (0..@size_y - 1).each do |i|
        yield @modules[i * @size_x, @size_x], i
      end
    end

    # Returns a module at the given coordinate.
    @[AlwaysInline]
    def [](x : Int, y : Int)
      @modules[y * @size_x + x]
    end

    @[AlwaysInline]
    protected def []=(x : Int, y : Int, value : UInt8)
      # We are absolutely sure that the index is within the bounds,
      # as the arrays are pre-allocated based on the given version
      # and all the set/get methods are called based on that size
      @modules.unsafe_put(y * @size_x + x, value)
    end

    @[AlwaysInline]
    protected def []=(x : Int, y : Int, w : Int, h : Int, value : UInt8)
      (x...x + w).each do |xx|
        (y...y + h).each do |yy|
          self[xx, yy] = value
        end
      end
    end

    protected def normalize
      @modules.map! do |v|
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
