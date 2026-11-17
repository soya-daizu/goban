require "./spec_helper"

module Goban
  describe QR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        version = QR::Version.new(1)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        QR::Template.draw_function_patterns(canvas, version)

        expected = 283 + 283 + 711 + 720 + 720 + 50 # = 2767
        QR::Mask.evaluate_score(canvas).should eq(expected)
      end

      # The score is computed on rows and columns packed into 64-bit words.
      # These place finder-like patterns at the end of a line and across
      # the word boundaries (bit 64) to check the shifts between words.
      {
        {11, 18135}, # 61 modules: 1 word, trailing light area reaches bit 63
        {12, 20662}, # 65 modules: 2 words, patterns straddle bit 64
        {28, 82097}, # 129 modules: 3 words
      }.each do |v, expected|
        it "reports correct score across word boundaries (version #{v})" do
          size = QR::Version.new(v).symbol_size
          canvas = Canvas(UInt8).new(size, size, 0)
          {1, 0, 1, 1, 1, 0, 1}.each_with_index do |bit, k|
            canvas[size - 7 + k, 0] = bit.to_u8
            canvas[0, 58 + k] = bit.to_u8 if size >= 65
          end

          QR::Mask.evaluate_score(canvas).should eq(expected)
        end
      end
    end
  end

  describe QR::Mask do
    describe "#apply_to" do
      # The masks are applied with precomputed patterns that repeat every
      # 12 modules, so check them against the mask definitions on the
      # largest symbol size
      it "inverts the data modules where the mask pattern holds" do
        size = 177
        rng = Random.new(1)
        original = Canvas(UInt8).new(size, size, 0_u8)
        original.data.map! { (rng.rand(2) == 0 ? 0xc0_u8 : 0_u8) | rng.rand(2).to_u8 }

        8.times do |i|
          canvas = original.clone
          QR::Mask.new(i).apply_to(canvas)

          size.times do |y|
            size.times do |x|
              value = original[x, y]
              expected = value & 0x80 == 0 && QR::Mask::MASK_PATTERNS[i].call(x, y) ? value ^ 1 : value
              canvas[x, y].should eq(expected)
            end
          end
        end
      end
    end
  end

  describe MQR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        version = MQR::Version.new(1)
        canvas = Canvas(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas[10, 0, 1, 6] = 1
        canvas[0, 10, 5, 1] = 1

        expected = 5 * 16 + 6 # = 86
        MQR::Mask.evaluate_score(canvas).should eq(expected)
      end
    end
  end
end
