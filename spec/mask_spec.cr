require "./spec_helper"

module Goban
  describe QRCode::Mask do
    describe ".evaluate_score" do
      it "reports correct score", tags: "a" do
        canvas = QRCode::Canvas.new(QRCode::Version.new(1), QRCode::ECLevel::Low)
        canvas.draw_function_patterns

        # 286 + 286 + 723 + 360 + 360 + 50
        QRCode::Mask.evaluate_score(canvas).should eq(2065)
      end
    end
  end
end
