require "./spec_helper"

module Goban
  describe QR::Mask do
    describe ".evaluate_score" do
      it "reports correct score" do
        drawer = QR::CanvasDrawer.new(QR::Version.new(1), ECC::Level::Low)
        drawer.draw_function_patterns

        # 283 + 283 + 711 + 360 + 360 + 50
        QR::Mask.evaluate_score(drawer.canvas).should eq(2047)
      end
    end
  end
end
