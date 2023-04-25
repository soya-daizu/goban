struct Goban::Segment
  # Module for building segmentations of the different encoding modes
  # for the given text string.
  module Segmenter
    extend self

    # Makes a list of the best encoding mode for the each given character
    # by dynamic programming algorithm. The code is based on:
    # https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes
    protected def compute_char_modes(chars : Array(Char), version : AbstractQR::Version)
      modes = {Segment::Mode::Byte, Segment::Mode::Alphanumeric, Segment::Mode::Numeric, Segment::Mode::Kanji}

      head_costs = modes.map do |m|
        mode_indicator_length = version.mode_indicator_length
        cci_bits_count = m.cci_bits_count(version) || Float32::INFINITY
        ((mode_indicator_length + cci_bits_count) * 6).to_f32
      end

      char_modes = Array(StaticArray(Segment::Mode, 4)).new(chars.size)
      prev_costs = StaticArray(Float32, 4).new { |i| head_costs[i] }

      chars.each do |c|
        c_modes = StaticArray(Segment::Mode, 4).new(Segment::Mode::Undefined)
        cur_costs = StaticArray(Float32, 4).new(Float32::INFINITY)

        # Byte mode is always calculated
        # bytesize * 8 / 6 bits per char
        cur_costs[0] = prev_costs[0] + c.bytesize * 8 * 6
        c_modes[0] = modes[0]

        is_alphanumeric = ALPHANUMERIC_CHARS.includes?(c)
        if is_alphanumeric
          # 33 / 6 bits per char
          cur_costs[1] = prev_costs[1] + 33
          c_modes[1] = modes[1]
        end

        is_numeric = c.ascii_number?
        if is_numeric
          # 20 / 6 bits per char
          cur_costs[2] = prev_costs[2] + 20
          c_modes[2] = modes[2]
        end

        is_kanji = c.bytesize > 1 && !c.to_s.encode("SHIFT_JIS", :skip).empty?
        if is_kanji
          # 78 / 6 bits per char
          cur_costs[3] = prev_costs[3] + 78
          c_modes[3] = modes[3]
        end

        modes.size.times do |j|
          modes.each_with_index do |from_mode, k|
            # ceil up to next integer
            new_cost = (cur_costs[k] / 6).ceil * 6 + head_costs[j]

            if c_modes[k] != Segment::Mode::Undefined && new_cost < cur_costs[j]
              cur_costs[j] = new_cost
              c_modes[j] = from_mode
            end
          end
        end

        char_modes.push(c_modes)
        prev_costs = cur_costs
      end

      cur_mode_index = 0
      modes.each_with_index do |mode, i|
        cur_mode_index = i if prev_costs[i] < prev_costs[cur_mode_index]
      end

      result = Array(Segment::Mode).new(chars.size)
      (0...chars.size).reverse_each do |i|
        cur_mode = char_modes[i][cur_mode_index]
        cur_mode_index = modes.index(cur_mode).not_nil!
        result.push(cur_mode)
      end

      result.reverse!
    end

    # Converts a list of encoding modes for each character to an actual segment objects.
    protected def make_segments(text : String, char_modes : Array(Segment::Mode))
      raise InternalError.new("Text size does not match the char modes") if text.size != char_modes.size

      result = [] of Segment
      count = 0

      text.size.times do |i|
        mode = char_modes[i]
        if i != text.size - 1 && mode == char_modes[i + 1]
          count += 1
          next
        end

        segment = Segment.new(mode, text[i - count..i])
        result.push(segment)
        count = 0
      end

      result
    end
  end
end
