require "./segment/*"

module Goban
  struct Segment
    getter mode : Mode
    getter char_count : Int32
    getter bit_stream : BitStream

    def initialize(@mode, @char_count, @bit_stream)
    end

    def self.numeric(text : String)
      digits = text.chars
      raise "Numeric data contains non-numeric characters" unless digits.all?(&.to_i?)

      bit_stream = BitStream.new(digits.size * 3 + (digits.size + 2) // 3)
      segment = self.new(Segment::Mode::Numeric, digits.size, bit_stream)
      digits.each_slice(3) do |slice|
        val = slice.join
        bit_stream.append_bits(val, slice.size * 3 + 1)
      end

      segment
    end

    def self.alpha_numeric(text : String)
      chars = text.chars.map { |c| ALPHA_NUMERIC_CHARS.index(c) || raise "Alphanumeric data contains unencodable characters" }

      bit_stream = BitStream.new(chars.size * 5 + (chars.size + 1) // 2)
      segment = self.new(Segment::Mode::AlphaNumeric, chars.size, bit_stream)
      chars.each_slice(2) do |slice|
        if slice.size == 1
          val = slice[0]
          size = 6
        else
          val = slice[0] * 45 + slice[1]
          size = 11
        end

        bit_stream.append_bits(val, size)
      end

      segment
    end

    def self.bytes(text : String)
      bytes = text.bytes
      bit_stream = BitStream.new(bytes.size * 8)
      segment = self.new(Segment::Mode::Byte, bytes.size, bit_stream)
      bytes.each do |byte|
        bit_stream.append_bits(byte, 8)
      end

      segment
    end

    def self.kanji(text : String)
      # In accordance to JIS X 0208, this doesn't include
      # extended characters as in CP932 or other variants
      bytes = text.encode("SHIFT_JIS")
      raise "Kanji data contains unencodable characters" unless bytes.size % 2 == 0
      bit_stream = BitStream.new(bytes.size // 2 * 13)
      segment = self.new(Segment::Mode::Kanji, text.size, bit_stream)

      bytes.each_slice(2).each do |byte_pair|
        if !(0x40..0xfc).includes?(byte_pair[1]) || byte_pair[1] == 0x7f
          # Probably unnecessary, but make sure the least
          # significant byte is in the range of SHIFT_JIS
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

        bit_stream.append_bits(val, 13)
      end

      segment
    end

    def self.count_total_bits(segments : Array(Segment), version : QRCode::Version)
      result = 0_u64
      segments.each do |segment|
        cci_bits_size = segment.mode.cci_bits_size(version)
        raise "Segment too long" if segment.char_count >= (1 << cci_bits_size)
        result += 4 + cci_bits_size + segment.bit_stream.size
      end
      result
    end
  end
end
