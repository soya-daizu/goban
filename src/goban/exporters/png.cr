require "stumpy_png"

module Goban
  module PNGExporter
    include StumpyPNG
    extend self

    def export(qr : QRCode, path : String, target_size : Int)
      size = qr.size + 4 * 2
      ratio = target_size / size
      self.export(qr, path, ratio.round.to_i, 4)
    end

    def export(qr : QRCode, path : String, mod_size : Int, blank_mods : Int)
      blank_size = blank_mods * mod_size
      size = qr.size * mod_size + blank_size * 2

      dark_color = RGBA.from_rgb_n(0, 0, 0, 8)
      light_color = RGBA.from_rgb_n(255, 255, 255, 8)
      canvas = Canvas.new(size, size, light_color)

      qr.size.times do |x|
        qr.size.times do |y|
          next unless qr.canvas.get_module(x, y)

          canvas_x = mod_size * x + blank_size
          canvas_y = mod_size * y + blank_size

          mod_size.times do |i|
            mod_size.times do |j|
              canvas[canvas_x + i, canvas_y + j] = dark_color
            end
          end
        end
      end

      StumpyPNG.write(canvas, path)
      size
    end
  end
end
