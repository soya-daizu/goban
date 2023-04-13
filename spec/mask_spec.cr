require "./spec_helper"

module Goban
  describe QR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        version = QR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        QR::Template.draw_function_patterns(canvas, version)

        expected = 283 + 283 + 711 + 360 + 360 + 50 # = 2047
        QR::Mask.evaluate_score(canvas).should eq(expected)
      end
    end
  end

  describe MQR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        version = MQR::Version.new(1)
        canvas = Matrix(UInt8).new(version.symbol_size, version.symbol_size, 0)
        canvas[10, 0, 1, 6] = 1
        canvas[0, 10, 5, 1] = 1

        expected = 5 * 16 + 6 # = 86
        MQR::Mask.evaluate_score(canvas).should eq(expected)
      end
    end
  end
end
