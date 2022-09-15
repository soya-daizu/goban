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
