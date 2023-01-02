require "./spec_helper"

module Goban
  struct MQR::CanvasDrawer
    def fill_border_for_test
      @canvas.fill_module(10, 0, 1, 6, 1)
      @canvas.fill_module(0, 10, 5, 1, 1)
    end
  end

  describe QR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.draw_function_patterns

        expected = 283 + 283 + 711 + 360 + 360 + 50 # = 2047
        QR::Mask.evaluate_score(drawer.canvas).should eq(expected)
      end
    end
  end

  describe MQR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        drawer = MQR::CanvasDrawer.new(MQR::Version.new(1), ECC::Level::Low)
        drawer.fill_border_for_test

        expected = 5 * 16 + 6 # = 86
        MQR::Mask.evaluate_score(drawer.canvas).should eq(expected)
      end
    end
  end
end
