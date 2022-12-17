struct Goban::QR
  struct Canvas
    # Returns the array of modules drawn on the canvas.
    getter modules : Slice(UInt8)
    # Length of the canvas's side.
    getter size : Int32

    protected def initialize(@size)
      @modules = Slice(UInt8).new(size ** 2)
    end

    protected def initialize(@size, @modules)
    end

    def clone
      Canvas.new(@size, @modules.dup)
    end

    def each_row(& : Slice(UInt8), Int32 ->)
      (0..@size - 1).each do |i|
        yield @modules[i * @size, @size], i
      end
    end

    # Returns a module at the given coordinate.
    @[AlwaysInline]
    def get_module(x : Int, y : Int)
      @modules[y * @size + x]
    end

    @[AlwaysInline]
    protected def set_module(x : Int, y : Int, value : UInt8)
      # We are absolutely sure that the index is within the bounds,
      # as the arrays are pre-allocated based on the given version
      # and all the set/get methods are called based on that size
      @modules.unsafe_put(y * @size + x, value)
    end

    @[AlwaysInline]
    protected def fill_module(x : Int, y : Int, w : Int, value : UInt8)
      @modules.fill(value, y * @size + x, w)
    end

    @[AlwaysInline]
    protected def reserve_modules(x : Int, y : Int, w : Int, h : Int)
      (x...x + w).each do |xx|
        (y...y + h).each do |yy|
          next if get_module(xx, yy) == 0xc1
          set_module(xx, yy, 0xc0)
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
      each_row do |row|
        row.each do |mod|
          print mod == 1 ? "██" : "  "
        end
        print '\n'
      end
      print '\n'
    end
  end
end
