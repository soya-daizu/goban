struct Goban::Segment
  # Module for optimizing segmentations of the different encoding modes
  # for the given text string.
  module Optimizer
    extend self

    # Returns a tuple of the optimized segments and QR Code version
    # for the given text and error correction level.
    def make_optimized_segments(text : String, ecl : QRCode::ECLevel) : Tuple(Array(Segment), QRCode::Version)
      chars = text.chars
      segments, version = nil, nil
      used_bits = 0

      # The number of the character count indicator bits which affect
      # the result of segmentation changes at the version 1, 10, and 27,
      # so we first calculate the segments at those boundaries, and adjust
      # the version number later
      {(1..9), (10..26), (27..40)}.each do |group|
        v = QRCode::Version.new(group.end)
        char_modes = compute_char_modes(chars, v)
        segments = make_segments(text, char_modes)

        cap_bits = v.max_data_codewords(ecl) * 8
        begin
          used_bits = Segment.count_total_bits(segments, v)
        rescue e
          next if e.message == "Segment too long"
          raise e
        end

        # If it's within the bound, that is the optimal segmentation
        # Now find the smallest version in that group that can hold its data
        if used_bits <= cap_bits
          group.each do |i|
            sml_v = QRCode::Version.new(i)
            sml_cap_bits = sml_v.max_data_codewords(ecl) * 8

            if used_bits <= sml_cap_bits
              version = sml_v
              break
            end
          end

          break
        end
      end
      raise "Text too long" unless segments && version

      {segments, version}
    end

    # Makes a list of the best encoding mode for the each given character
    # by dynamic programming algorithm. The code is based on:
    # https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes
    private def compute_char_modes(chars : Array(Char), version : QRCode::Version)
      modes = {Segment::Mode::Byte, Segment::Mode::Alphanumeric, Segment::Mode::Numeric, Segment::Mode::Kanji}
      head_costs = modes.map { |m| 4 + m.cci_bits_size(version) * 6 }
      char_modes = Array(StaticArray(Segment::Mode, 4)).new(chars.size)
      prev_costs = head_costs.clone

      chars.each do |c|
        c_modes = StaticArray(Segment::Mode, 4).new(Segment::Mode::Undefined)
        cur_costs = StaticArray(Int32, 4).new(Int32::MAX)

        # Byte mode is always calculated
        cur_costs[0] = prev_costs[0] + c.bytesize * 8 * 6
        c_modes[0] = modes[0]

        is_alphanumeric = ALPHANUMERIC_CHARS.includes?(c)
        if is_alphanumeric
          cur_costs[1] = prev_costs[1] + 33
          c_modes[1] = modes[1]
        end

        is_numeric = c.ascii_number?
        if is_numeric
          cur_costs[2] = prev_costs[2] + 20
          c_modes[2] = modes[2]
        end

        is_kanji = c.bytesize > 1 && !c.to_s.encode("SHIFT_JIS", :skip).empty?
        if is_kanji
          cur_costs[3] = prev_costs[3] + 78
          c_modes[3] = modes[3]
        end

        modes.size.times do |j|
          modes.each_with_index do |from_mode, k|
            if cur_costs[k] == Int32::MAX
              new_cost = cur_costs[k]
            else
              new_cost = cur_costs[k] + head_costs[j]
            end

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
    private def make_segments(text : String, char_modes : Array(Segment::Mode))
      raise "Text size does not match the char modes" if text.size != char_modes.size

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
