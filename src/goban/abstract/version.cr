module Goban::AbstractQR
  abstract struct Version
    include Comparable(Int)

    getter value

    getter symbol_size

    protected getter mode_indicator_length

    protected def initialize(@value, @symbol_size)
    end

    def <=>(other : Int)
      @value <=> other
    end

    def to_i
      value
    end
  end
end
