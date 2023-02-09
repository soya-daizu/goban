require "../abstract/mask"

struct Goban::RMQR < Goban::AbstractQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask < AbstractQR::Mask
    MASK_PATTERN = ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 }

    def initialize
      @value = 0_u8
      @mask_pattern = MASK_PATTERN
    end
  end
end
