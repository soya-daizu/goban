require "./segment/*"

module Goban
  # Represents a segment of QR Code data that holds its data bits and encoding type.
  struct Segment
    getter mode : Mode
    getter char_count : Int32
    getter bit_stream : BitStream

    ALPHANUMERIC_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"

    private def initialize(@mode, @char_count, @bit_stream)
    end

    def self.new(mode : Mode, text : String)
      case mode
      when .numeric?
        self.numeric(text)
      when .alphanumeric?
        self.alphanumeric(text)
      when .byte?
        self.byte(text)
      when .kanji?
        self.kanji(text)
      else
        raise "Unsupported mode"
      end
    end

    # Shorthand method for creating a Numeric mode segment.
    def self.numeric(text : String)
      digits = text.chars
      raise "Numeric data contains non-numeric characters" unless digits.all?(&.ascii_number?)

      bit_stream = BitStream.new(digits.size * 3 + (digits.size + 2) // 3)
      segment = self.new(Segment::Mode::Numeric, digits.size, bit_stream)
      digits.each_slice(3) do |slice|
        val = slice.join.to_u32
        bit_stream.push_bits(val, slice.size * 3 + 1)
      end

      segment
    end

    # Shorthand method for creating a Alphanumeric mode segment.
    def self.alphanumeric(text : String)
      chars = text.chars.map do |c|
        ALPHANUMERIC_CHARS.index(c) || raise "Alphanumeric data contains unencodable characters"
      end

      bit_stream = BitStream.new(chars.size * 5 + (chars.size + 1) // 2)
      segment = self.new(Segment::Mode::Alphanumeric, chars.size, bit_stream)
      chars.each_slice(2) do |slice|
        if slice.size == 1
          val = slice[0]
          size = 6
        else
          val = slice[0] * 45 + slice[1]
          size = 11
        end

        bit_stream.push_bits(val, size)
      end

      segment
    end

    # Shorthand method for creating a Byte mode segment.
    def self.byte(text : String)
      bytes = text.bytes
      bit_stream = BitStream.new(bytes.size * 8)
      segment = self.new(Segment::Mode::Byte, bytes.size, bit_stream)
      bytes.each do |byte|
        bit_stream.push_bits(byte, 8)
      end

      segment
    end

    # Shorthand method for creating a Kanji mode segment.
    def self.kanji(text : String)
      # In accordance to JIS X 0208, this doesn't include
      # extended characters as in CP932 or other variants
      bytes = text.encode("SHIFT_JIS")
      raise "Kanji data contains unencodable characters" unless bytes.size % 2 == 0
      bit_stream = BitStream.new(bytes.size // 2 * 13)
      segment = self.new(Segment::Mode::Kanji, text.size, bit_stream)

      bytes.each_slice(2).each do |byte_pair|
        if !(0x40..0xfc).includes?(byte_pair[1]) || byte_pair[1] == 0x7f
          # Probably unnecessary, but making sure that the least
          # significant byte is within the range of SHIFT_JIS
          raise "Kanji data contains unencodable characters"
        end

        val = (byte_pair[0].to_u16 << 8) | byte_pair[1]
        if (0x8140..0x9ffc).includes?(val)
          val -= 0x8140
        elsif (0xe040..0xebbf).includes?(val)
          val -= 0xc140
        else
          # Again, this should be caught in the first place
          # as it's not a valid SHIFT_JIS code anyway
          raise "Kanji data contains unencodable characters"
        end
        val = (val >> 8) * 0xc0 + (val & 0xff)

        bit_stream.push_bits(val, 13)
      end

      segment
    end

    # Count number of bits in the given list of segments.
    def self.count_total_bits(segments : Array(Segment), version : AbstractQR::Version)
      result = 0
      segments.each do |segment|
        cci_bits_count = segment.mode.cci_bits_count(version)
        raise "Invalid segment" if !cci_bits_count
        raise "Segment too long" if segment.char_count >= (1 << cci_bits_count)
        result += 4 + cci_bits_count + segment.bit_stream.size
      end
      result
    end
  end
end
