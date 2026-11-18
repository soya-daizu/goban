struct Goban::Segment
  # Module for building segmentations of the different encoding modes
  # for the given text string.
  module Segmenter
    extend self

    # Encoding modes considered by the segmentation, in the order of the
    # cost arrays below.
    private MODES = {Segment::Mode::Byte, Segment::Mode::Alphanumeric, Segment::Mode::Numeric, Segment::Mode::Kanji}

    # Character classes. Every character can be encoded in Byte mode.
    private CLASS_ALPHANUMERIC = 1_u8
    private CLASS_NUMERIC      = 2_u8
    private CLASS_KANJI        = 4_u8

    # Costs are in sixths of a bit, so that the per-character costs of all
    # modes are integers. Unreachable states have this cost. It is a multiple
    # of 6 so that rounding it up to a whole bit leaves it unchanged.
    private INFINITE_COST = 6_i64 << 50

    # A text prepared for segmentation. The characters are classified only
    # once, and the segments computed for a version are reused for the other
    # versions that have the same mode indicator and character count
    # indicator lengths, since the segmentation depends only on those.
    class Analysis
      getter text : String
      # Bitwise OR of the `CLASS_*` flags of each character
      getter classes : Slice(UInt8)
      # Number of bytes of each character, as used for the Byte mode cost
      getter bytesizes : Slice(UInt8)
      # Byte offset of each character in the text, followed by the text bytesize
      getter byte_offsets : Slice(Int32)
      # Lower bound of the number of data bits of any segmentation of the text,
      # excluding the mode indicators and character count indicators. Versions
      # with a smaller capacity can be skipped without segmenting the text.
      getter min_data_bits : Int32

      @cache = {} of Tuple(Int32, Int32?, Int32?, Int32?, Int32?) => Array(Segment)

      def initialize(@text : String)
        size = @text.size
        @classes = Slice(UInt8).new(size)
        @bytesizes = Slice(UInt8).new(size)
        @byte_offsets = Slice(Int32).new(size + 1)

        # In sixths of a bit, as in `Segmenter.compute_char_modes`
        min_cost = 0_i64

        reader = Char::Reader.new(@text)
        i = 0
        while reader.has_next?
          char = reader.current_char
          klass = Segmenter.classify(char)
          @byte_offsets[i] = reader.pos
          @bytesizes[i] = char.bytesize.to_u8
          @classes[i] = klass
          reader.next_char
          # The actual number of bytes in the text, which differs from the
          # bytesize of the replacement character for invalid UTF-8 sequences
          min_cost += Segmenter.min_char_cost(klass, reader.pos - @byte_offsets[i])
          i += 1
        end
        @byte_offsets[size] = @text.bytesize
        @min_data_bits = ((min_cost + 5) // 6).to_i32
      end

      def size
        @classes.size
      end

      # Returns the optimal segments for the given version.
      def segments_for(version : AbstractQR::Version)
        key = {
          version.mode_indicator_length,
          MODES[0].cci_bits_count(version),
          MODES[1].cci_bits_count(version),
          MODES[2].cci_bits_count(version),
          MODES[3].cci_bits_count(version),
        }
        @cache[key] ||= begin
          char_modes = Segmenter.compute_char_modes(self, version)
          Segmenter.make_segments(self, char_modes)
        end
      end
    end

    protected def classify(char : Char)
      klass = 0_u8
      klass |= CLASS_ALPHANUMERIC if Segment.alphanumeric_index(char)
      klass |= CLASS_NUMERIC if char.ascii_number?
      klass |= CLASS_KANJI if char.bytesize > 1 && UNICODE_SHIFTJIS_TABLE.has_key?(char.ord)
      klass
    end

    # The lowest cost (in sixths of a bit) of the character among the modes
    # that can encode it. Each segment needs at least the sum of these costs
    # of its characters, since its data bits are the per-character costs of
    # its mode rounded up.
    protected def min_char_cost(klass : UInt8, bytesize : Int32)
      cost = bytesize.to_i64 * 8 * 6
      cost = Math.min(cost, 33_i64) if klass & CLASS_ALPHANUMERIC != 0
      cost = Math.min(cost, 20_i64) if klass & CLASS_NUMERIC != 0
      cost = Math.min(cost, 78_i64) if klass & CLASS_KANJI != 0
      cost
    end

    # Makes a list of the best encoding mode for the each given character
    # by dynamic programming algorithm. The code is based on:
    # https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes
    protected def compute_char_modes(analysis : Analysis, version : AbstractQR::Version)
      mode_indicator_length = version.mode_indicator_length
      head_costs = StaticArray(Int64, 4).new do |i|
        cci_bits_count = MODES[i].cci_bits_count(version)
        cci_bits_count ? (mode_indicator_length + cci_bits_count).to_i64 * 6 : INFINITE_COST
      end

      size = analysis.size
      classes = analysis.classes
      bytesizes = analysis.bytesizes
      # Mode to come from for each character and each mode to end in
      char_modes = Slice(StaticArray(Segment::Mode, 4)).new(size, StaticArray(Segment::Mode, 4).new(Segment::Mode::Undefined))
      prev_costs = head_costs

      size.times do |i|
        klass = classes.unsafe_fetch(i)
        c_modes = StaticArray(Segment::Mode, 4).new(Segment::Mode::Undefined)
        cur_costs = StaticArray(Int64, 4).new(INFINITE_COST)

        # Byte mode is always calculated
        # bytesize * 8 / 6 bits per char
        cur_costs[0] = self.saturate(prev_costs[0] + bytesizes.unsafe_fetch(i).to_i64 * 8 * 6)
        c_modes[0] = MODES[0]

        if klass & CLASS_ALPHANUMERIC != 0
          # 33 / 6 bits per char
          cur_costs[1] = self.saturate(prev_costs[1] + 33)
          c_modes[1] = MODES[1]
        end

        if klass & CLASS_NUMERIC != 0
          # 20 / 6 bits per char
          cur_costs[2] = self.saturate(prev_costs[2] + 20)
          c_modes[2] = MODES[2]
        end

        if klass & CLASS_KANJI != 0
          # 78 / 6 bits per char
          cur_costs[3] = self.saturate(prev_costs[3] + 78)
          c_modes[3] = MODES[3]
        end

        4.times do |j|
          4.times do |k|
            # ceil up to next whole bit
            new_cost = self.saturate((cur_costs[k] + 5) // 6 * 6 + head_costs[j])

            if c_modes[k] != Segment::Mode::Undefined && new_cost < cur_costs[j]
              cur_costs[j] = new_cost
              c_modes[j] = MODES[k]
            end
          end
        end

        char_modes[i] = c_modes
        prev_costs = cur_costs
      end

      cur_mode_index = 0
      4.times do |i|
        cur_mode_index = i if prev_costs[i] < prev_costs[cur_mode_index]
      end

      result = Array(Segment::Mode).new(size, Segment::Mode::Undefined)
      (0...size).reverse_each do |i|
        cur_mode = char_modes[i][cur_mode_index]
        cur_mode_index = MODES.index(cur_mode).not_nil!
        result[i] = cur_mode
      end

      result
    end

    # Clamps the cost so that adding to an unreachable state keeps it unreachable.
    @[AlwaysInline]
    private def saturate(cost : Int64)
      cost < INFINITE_COST ? cost : INFINITE_COST
    end

    # Converts a list of encoding modes for each character to an actual segment objects.
    protected def make_segments(analysis : Analysis, char_modes : Array(Segment::Mode))
      raise InternalError.new("Text size does not match the char modes") if analysis.size != char_modes.size

      text = analysis.text
      offsets = analysis.byte_offsets
      result = [] of Segment
      start = 0

      char_modes.size.times do |i|
        mode = char_modes[i]
        next if i != char_modes.size - 1 && mode == char_modes[i + 1]

        byte_start = offsets[start]
        segment = Segment.new(mode, text.byte_slice(byte_start, offsets[i + 1] - byte_start))
        result.push(segment)
        start = i + 1
      end

      result
    end
  end
end
