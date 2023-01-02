module Goban::AbstractQR
  abstract struct Version
    include Comparable(Int)

    getter value : UInt8

    getter symbol_size : Int32

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
