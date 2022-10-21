module Goban
  module SVGExporter
    extend self

    def export(qr : QRCode, path : String)
      string = svg_string(qr, 4)
      File.write(path, string)
    end

    def svg_string(qr : QRCode, blank_mods : Int)
      parts = [] of String

      qr.size.times do |x|
        qr.size.times do |y|
          next unless qr.canvas.get_module(x, y)
          parts.push("M#{x + blank_mods},#{y + blank_mods}h1v1h-1z")
        end
      end

      return %(<?xml version="1.0" encoding="UTF-8"?>) \
             %(<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">) \
             %(<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 #{qr.size + blank_mods * 2} #{qr.size + blank_mods * 2}" stroke="none">) \
             %(<rect width="100%" height="100%" fill="#fff"/>) \
             %(<path d="#{parts.join(' ')}" fill="#000"/>) \
             %(</svg>)
    end
  end
end
