module Goban::AbstractQR
  abstract struct Mask
    getter value : UInt8

    @mask_pattern : Proc(Int32, Int32, Bool)

    protected def initialize(@value, @mask_pattern)
    end

    # Apply mask to the given canvas.
    # Call this method again to reverse the applied mask.
    protected def apply_to(canvas : Canvas)
      canvas.size_y.times do |y|
        canvas.size_x.times do |x|
          value = canvas.get_module(x, y)
          next if value & 0x80 > 0

          invert = @mask_pattern.call(x, y) ? 1 : 0
          canvas.set_module(x, y, value ^ invert)
        end
      end
    end
  end
end
