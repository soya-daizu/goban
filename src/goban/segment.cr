require "./segment/*"

module Goban
  # Represents a segment of QR Code data that holds its data bits and encoding type.
  struct Segment
    getter mode : Mode
    getter char_count : Int32
    getter text : String
    getter bit_size : Int32

    ALPHANUMERIC_CHARS = {
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
      'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
      'U', 'V', 'W', 'X', 'Y', 'Z', ' ', '$', '%', '*',
      '+', '-', '.', '/', ':',
    }

    private def initialize(@mode, @char_count, @text, @bit_size)
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
        raise InputError.new("Unsupported mode")
      end
    end

    # Shorthand method for creating a Numeric mode segment.
    def self.numeric(text : String)
      raise InputError.new("Numeric data contains non-numeric characters") unless text.each_char.all?(&.ascii_number?)

      bit_size = text.size * 3 + (text.size + 2) // 3
      self.new(Segment::Mode::Numeric, text.size, text, bit_size)
    end

    # Shorthand method for creating a Alphanumeric mode segment.
    def self.alphanumeric(text : String)
      is_all_alphanumeric = text.each_char.all? do |c|
        ALPHANUMERIC_CHARS.index(c)
      end
      raise InputError.new("Alphanumeric data contains unencodable characters") unless is_all_alphanumeric

      bit_size = text.size * 5 + (text.size + 1) // 2
      self.new(Segment::Mode::Alphanumeric, text.size, text, bit_size)
    end

    # Shorthand method for creating a Byte mode segment.
    def self.byte(text : String)
      self.new(Segment::Mode::Byte, text.bytesize, text, text.bytesize * 8)
    end

    # Shorthand method for creating a Kanji mode segment.
    def self.kanji(text : String)
      bit_size = text.size * 13
      segment = self.new(Segment::Mode::Kanji, text.size, text, bit_size)
    end

    protected def produce_bits
      case @mode
      when .numeric?
        produce_bits_numeric
      when .alphanumeric?
        produce_bits_alphanumeric
      when .byte?
        produce_bits_byte
      when .kanji?
        produce_bits_kanji
      else
        raise InternalError.new("Unsupported mode")
      end
    end

    private macro produce_bits_numeric
      @text.each_char.each_slice(3, reuse: true).map do |slice|
        val = slice.join.to_u16
        size = slice.size * 3 + 1

        next val, size
      end
    end

    private macro produce_bits_alphanumeric
      @text.each_char.each_slice(2, reuse: true).map do |slice|
        if slice.size == 1
          val = ALPHANUMERIC_CHARS.index!(slice[0])
          size = 6
        else
          val = ALPHANUMERIC_CHARS.index!(slice[0]) * 45 + ALPHANUMERIC_CHARS.index!(slice[1])
          size = 11
        end

        next val, size
      end
    end

    private macro produce_bits_byte
      @text.each_byte.map do |byte|
        next byte, 8
      end
    end

    private macro produce_bits_kanji
      @text.each_char.map do |char|
        v = UNICODE_SHIFTJIS_TABLE[char.ord] rescue raise InputError.new("Kanji data contains unencodable characters")
        byte_pair = {v >> 8, v & 0x00ff}

        val = (byte_pair[0].to_u16 << 8) | byte_pair[1]
        if val.in?(0x8140..0x9ffc)
          val -= 0x8140
        elsif val.in?(0xe040..0xebbf)
          val -= 0xc140
        else
          raise InputError.new("Kanji data contains unencodable characters")
        end
        val = (val >> 8) * 0xc0 + (val & 0xff)

        next val, 13
      end
    end

    # For decoding
    protected def self.new(mode : Mode, char_count : Int, bit_stream : BitStream)
      text, bit_size = nil, 0
      case mode
      when .numeric?
        consume_bits_numeric
      when .alphanumeric?
        consume_bits_alphanumeric
      when .byte?
        consume_bits_byte
      when .kanji?
        consume_bits_kanji
      else
        raise InputError.new("Unsupported mode")
      end

      self.new(mode, char_count, text, bit_size)
    end

    private macro consume_bits_numeric
      text = String.build(capacity: char_count) do |str|
        remaining_char_count = char_count
        while remaining_char_count > 0
          slice_size = Math.min(remaining_char_count, 3)

          size = slice_size * 3 + 1
          val = bit_stream.read_bits(size)
          str << val.to_s(precision: slice_size)

          remaining_char_count -= slice_size
          bit_size += size
        end
      end
    end

    private macro consume_bits_alphanumeric
      text = String.build(capacity: char_count) do |str|
        remaining_char_count = char_count
        while remaining_char_count > 0
          slice_size = Math.min(remaining_char_count, 2)

          size = slice_size == 1 ? 6 : 11
          val = bit_stream.read_bits(size)
          if slice_size == 1
            str << ALPHANUMERIC_CHARS[val]
          else
            val1 = val // 45
            val2 = val - val1 * 45
            str << ALPHANUMERIC_CHARS[val1]
            str << ALPHANUMERIC_CHARS[val2]
          end

          remaining_char_count -= slice_size
          bit_size += size
        end
      end
    end

    private macro consume_bits_byte
      bit_size = char_count * 8
      bytes = Slice(UInt8).new(char_count) do
        bit_stream.read_bits(8).to_u8
      end
      text = String.new(bytes)
    end

    private macro consume_bits_kanji
      bit_size = char_count * 13
      bytes = Slice(UInt8).new(char_count * 2)
      (0...char_count * 2).step(2) do |i|
        bits = bit_stream.read_bits(13)

        val = ((bits // 0xc0) << 8) | (bits % 0xc0)
        val += val < 0x1f00 ? 0x8140 : 0xc140

        bytes[i] = (val >> 8).to_u8
        bytes[i + 1] = (val & 0xff).to_u8
      end
      text = String.new(bytes, "SHIFT_JIS", :skip)
    end

    # Count number of bits in the given list of segments.
    def self.count_total_bits(segments : Array(Segment), version : AbstractQR::Version)
      result = 0
      segments.each do |segment|
        cci_bits_count = segment.mode.cci_bits_count(version)
        raise InputError.new("Invalid segment") if !cci_bits_count
        raise InputError.new("Segment too long") if segment.char_count >= (1 << cci_bits_count)
        result += version.mode_indicator_length + cci_bits_count + segment.bit_size
      end
      result
    end
  end
end
