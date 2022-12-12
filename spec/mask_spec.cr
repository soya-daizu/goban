require "./spec_helper"

module Goban
  describe QR::Mask do
    describe ".evaluate_score" do
      it "reports correct score", tags: "a" do
        canvas = QR::Canvas.new(QR::Version.new(1), QR::ECLevel::Low)
        canvas.draw_function_patterns

        # 286 + 286 + 723 + 360 + 360 + 50
        QR::Mask.evaluate_score(canvas).should eq(2065)
      end
    end
  end
end
