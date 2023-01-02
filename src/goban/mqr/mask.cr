struct Goban::MQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask
    # Mask identifier. Valid values are integers from 0 to 7.
    getter value : UInt8

    @mask_pattern : Proc(Int32, Int32, Bool)

    MASK_PATTERNS = {
      ->(x : Int32, y : Int32) { y & 1 == 0 },
      ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x * y) & 1) + (x * y) % 3) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x + y) & 1) + (x * y) % 3) & 1 == 0 },
    }

    def initialize(@value)
      raise "Invalid mask number" if @value > 3
      @mask_pattern = MASK_PATTERNS[@value]
    end

    # Apply mask to the given canvas.
    # Call this method again to reverse the applied mask.
    protected def apply_to(canvas : Canvas)
      canvas.size.times do |y|
        canvas.size.times do |x|
          value = canvas.get_module(x, y)
          next if value & 0x80 > 0

          invert = @mask_pattern.call(x, y) ? 1 : 0
          canvas.set_module(x, y, value ^ invert)
        end
      end
    end

    private def get_symbol_num(ver : Version, ecl : ECC::Level)
      case ver.to_i
      when 1
        return 0b000
      when 2
        return 0b001 if ecl.low?
        return 0b010 if ecl.medium?
      when 3
        return 0b011 if ecl.low?
        return 0b100 if ecl.medium?
      when 4
        return 0b101 if ecl.low?
        return 0b110 if ecl.medium?
        return 0b111 if ecl.quartile?
      end

      raise "Invalid EC level or version"
    end

    protected def draw_format_modules(canvas : Canvas, ver : Version, ecl : ECC::Level)
      data = (get_symbol_num(ver, ecl) << 2 | @value).to_u32
      rem = data
      10.times do
        rem = (rem << 1) ^ ((rem >> 9) * 0x537)
      end
      bits = (data << 10 | rem) ^ 0x4445

      (0...8).each do |i|
        bit = (bits >> i & 1).to_u8 | 0xc0
        pos = i + 1
        canvas.set_module(8, pos, bit)
      end

      (0...7).each do |i|
        bit = (bits >> 14 - i & 1).to_u8 | 0xc0
        pos = i + 1
        canvas.set_module(pos, 8, bit)
      end
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    protected def self.evaluate_score(canvas : Canvas)
      s1, s2 = 0, 0
      canvas.size.times do |i|
        s1 += canvas.get_module(canvas.size - 1, i) & 1
        s2 += canvas.get_module(i, canvas.size - 1) & 1
      end

      if s1 <= s2
        s1 * 16 + s2
      else
        s2 * 16 + s1
      end
    end
  end
end
