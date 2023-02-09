require "../abstract/mask"

struct Goban::MQR < Goban::AbstractQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask < AbstractQR::Mask
    MASK_PATTERNS = {
      ->(x : Int32, y : Int32) { y & 1 == 0 },
      ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x * y) & 1) + (x * y) % 3) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x + y) & 1) + (x * y) % 3) & 1 == 0 },
    }

    MIN = 0_u8
    MAX = 3_u8

    def initialize(value)
      raise "Invalid mask number" unless (MIN..MAX).includes?(value)
      @value = value.to_u8
      @mask_pattern = MASK_PATTERNS[@value]
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
