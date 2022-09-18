require "./qrcode/*"

module Goban
  struct QRCode
    getter version : Version
    getter ecl : ECLevel
    getter modules : Array(Bool)
    getter size : Int32

    def initialize(@version, @ecl, @modules)
      @size = @version.symbol_size
    end

    def print_to_console
      border = 4
      @size.times do |y|
        @size.times do |x|
          print @modules[y * @size + x] ? "██" : "  "
        end
        print '\n'
      end
      print '\n'
    end

    def self.encode_string(text : String, ecl : ECLevel = ECLevel::Medium, upgrade : Bool = false)
      bytes = text.bytes

      version, segments = nil, nil
      used_bits = 0
      (Version::MIN..Version::MAX).each do |v|
        v = Version.new(v)
        if v == 1 || v == 10 || v == 27
          segments = Optimizer.make_optimized_segments(text, v)
        end
        raise "Segment optimization failed" unless segments
        
        cap_bits = v.max_data_codewords(ecl) * 8
        used_bits = Segment.count_total_bits(segments, v)

        if used_bits <= cap_bits
          version = v
          break
        end
      end
      raise "Text too long" unless version && segments

      if upgrade
        (ecl.value + 1..ECLevel::High.value).each do |new_ecl|
          new_ecl = ECLevel.new(new_ecl)
          break if used_bits > version.max_data_codewords(new_ecl) * 8
          ecl = new_ecl
        end
      end

      self.encode_segments(segments, ecl, version)
    end

    def self.encode_segments(segments : Array(Segment), ecl : ECLevel, version : Version)
      bit_stream = BitStream.new(version.max_data_codewords(ecl) * 8)
      segments.each do |segment|
        bit_stream.append_segment_bits(segment, version)
      end
      bit_stream.append_terminator_bits(version, ecl)
      bit_stream.append_padding_bits

      data_codewords = RSCode.add_ec_codewords(bit_stream.to_bytes, version, ecl)

      canvas = Canvas.new(version, ecl)
      canvas.draw_function_patterns
      canvas.draw_data_codewords(data_codewords)
      canvas.apply_best_mask
      modules = canvas.modules

      self.new(version, ecl, modules)
    end
  end
end
