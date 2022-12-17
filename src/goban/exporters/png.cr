require "stumpy_png"

module Goban
  # Helper module to generate PNG image for the QR Code object. Requires `stumpy_png` as a dependency.
  module PNGExporter
    include StumpyPNG
    extend self

    # Generates a PNG image with the given target size and exports to the given path.
    # Note that the size of the resulting image may not be equal to the target size specified.
    def export(qr : QR, path : String, target_size : Int)
      size = qr.size + 4 * 2
      ratio = target_size / size
      self.export(qr, path, ratio.round.to_i, 4)
    end

    # Generates a PNG image with the given module size and blank modules, and exportes to the
    # given path.
    #
    # `mod_size` refers to the number of pixels used for each module in the QR Code symbol,
    # and `blank_mods` is the size of the white border around the symbol.
    def export(qr : QR, path : String, mod_size : Int, blank_mods : Int)
      blank_size = blank_mods * mod_size
      size = qr.size * mod_size + blank_size * 2

      dark_color = RGBA.from_rgb_n(0, 0, 0, 8)
      light_color = RGBA.from_rgb_n(255, 255, 255, 8)
      canvas = Canvas.new(size, size, light_color)

      qr.canvas.each_row do |row, x|
        row.each_with_index do |mod, y|
          next unless mod == 1

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
