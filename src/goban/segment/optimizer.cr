struct Goban::Segment
  module Optimizer
    extend self

    def make_optimized_segments(text : String, ecl : QRCode::ECLevel)
      chars = text.chars
      segments, version = nil, nil
      used_bits = 0
      (QRCode::Version::MIN..QRCode::Version::MAX).each do |v|
        v = QRCode::Version.new(v)
        if v == 1 || v == 10 || v == 27
          char_modes = compute_char_modes(chars, v)
          segments = make_segments(text, char_modes)
        end
        raise "Segment optimization failed" unless segments

        cap_bits = v.max_data_codewords(ecl) * 8
        used_bits = Segment.count_total_bits(segments, v)

        if used_bits <= cap_bits
          version = v
          break
        end
      end
      raise "Text too long" unless segments && version

      {segments, version}
    end

    private def compute_char_modes(chars : Array(Char), version : QRCode::Version)
      modes = {Segment::Mode::Byte, Segment::Mode::Alphanumeric, Segment::Mode::Numeric, Segment::Mode::Kanji}
      head_costs = modes.map { |m| 4 + m.cci_bits_size(version) * 6 }
      char_modes = Array(StaticArray(Segment::Mode, 4)).new(chars.size)
      prev_costs = head_costs.clone

      chars.each do |c|
        c_modes = StaticArray(Segment::Mode, 4).new(Segment::Mode::Invalid)
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

            if c_modes[k] != Segment::Mode::Invalid && new_cost < cur_costs[j]
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
