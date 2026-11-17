require "spec"
require "../src/goban"

def convert_canvas_to_text(canvas : Goban::Canvas(UInt8))
  String.build do |io|
    canvas.each_row do |row|
      row.each do |mod|
        io << (mod == 1 ? "██" : "  ")
      end
      io << '\n'
    end
  end.lines
end

def convert_text_to_canvas(lines : Array(String))
  canvas = Goban::Canvas(UInt8).new(lines[0].size // 2, lines.size, 0)

  lines.each_with_index do |line, y|
    line.each_char.each_slice(2, reuse: true).with_index do |slice, x|
      mod = slice[0] == '█' ? 1_u8 : 0_u8
      canvas[x, y] = mod
    end
  end

  canvas
end

ALL_NUMERIC_STR  = "0123456789"
ALL_NUMERIC_SEGS = [
  Goban::Segment.numeric("0123456789"),
]

ALL_ALPHANUMERIC_STR  = "ABCDEFG"
ALL_ALPHANUMERIC_SEGS = [
  Goban::Segment.alphanumeric("ABCDEFG"),
]

ALL_BYTE_STR  = "aЉ윇😱"
ALL_BYTE_SEGS = [
  Goban::Segment.byte("aЉ윇😱"),
]

ALL_KANJI_STR  = "水星の魔女"
ALL_KANJI_SEGS = [
  Goban::Segment.kanji("水星の魔女"),
]

NUMERIC_ALPHANUMERIC_1_STR  = "012345A"
NUMERIC_ALPHANUMERIC_1_SEGS = [
  Goban::Segment.alphanumeric("012345A"),
]
NUMERIC_ALPHANUMERIC_2_STR  = "0123456A"
NUMERIC_ALPHANUMERIC_2_SEGS = [
  Goban::Segment.numeric("0123456"),
  Goban::Segment.alphanumeric("A"),
]

NUMERIC_BYTE_1_STR  = "012a"
NUMERIC_BYTE_1_SEGS = [
  Goban::Segment.byte("012a"),
]
NUMERIC_BYTE_2_STR  = "0123a"
NUMERIC_BYTE_2_SEGS = [
  Goban::Segment.numeric("0123"),
  Goban::Segment.byte("a"),
]

ALPHANUMERIC_BYTE_1_STR  = "ABCDEa"
ALPHANUMERIC_BYTE_1_SEGS = [
  Goban::Segment.byte("ABCDEa"),
]
ALPHANUMERIC_BYTE_2_STR  = "ABCDEFa"
ALPHANUMERIC_BYTE_2_SEGS = [
  Goban::Segment.alphanumeric("ABCDEF"),
  Goban::Segment.byte("a"),
]

SAMPLE_STR  = "こんにちwa、世界！ 123"
SAMPLE_SEGS = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.byte("wa"),
  Goban::Segment.kanji("、世界！"),
  Goban::Segment.alphanumeric(" 123"),
]

SAMPLE_STR_2  = "こんにちwa"
SAMPLE_SEGS_2 = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.byte("wa"),
]

SAMPLE_RESULT_MODS_QR = <<-STRING.lines
██████████████  ██    ██  ██  ██    ██████████████
██          ██  ████        ██      ██          ██
██  ██████  ██            ████  ██  ██  ██████  ██
██  ██████  ██  ██████    ██  ██    ██  ██████  ██
██  ██████  ██    ████████  ████    ██  ██████  ██
██          ██    ██████  ██  ████  ██          ██
██████████████  ██  ██  ██  ██  ██  ██████████████
                ██  ██      ██                    
██  ████  ██████    ██  ██    ██    ██    ██  ████
████████████  ██    ██        ████    ██    ██████
████  ██  ████████    ██  ██  ██  ██  ██          
████      ██      ██      ██    ████      ████    
██████  ██  ████████  ████  ██        ██████      
  ██████████    ██    ████        ██  ████    ██  
  ██████  ██████  ██████  ████████    ████      ██
██  ██  ██    ██  ██████    ██  ██  ██    ████████
    ██  ██████    ████  ██  ████████████████  ████
                ██              ██      ██  ██    
██████████████  ██        ██    ██  ██  ██████  ██
██          ██  ████  ██  ██    ██      ██    ██  
██  ██████  ██    ██          ██████████████████  
██  ██████  ██  ██  ██        ██  ████    ██    ██
██  ██████  ██  ██          ██    ██    ████████  
██          ██    ██  ██████    ██    ██  ██      
██████████████  ██    ████    ██    ████    ██    
STRING

SAMPLE_RESULT_MODS_MQR = <<-STRING.lines
██████████████  ██  ██  ██  ██
██          ██  ████████    ██
██  ██████  ██      ████  ████
██  ██████  ██    ██████  ████
██  ██████  ██        ████████
██          ██    ██  ██  ████
██████████████  ████    ██████
                  ██  ████    
██████████    ██  ██    ██████
      ██████  ██████████  ██  
██  ██  ████  ████████  ██  ██
  ██  ██  ██████████    ██████
██  ██    ████  ██████████  ██
  ██  ████      ██████  ██  ██
████████████  ██  ██      ████
STRING

SAMPLE_RESULT_MODS_RMQR = <<-STRING.lines
██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████
██          ██        ██  ████████  ██  ██  ██  ██  ██
██  ██████  ██  ████      ██  ██      ██  ████  ██  ██
██  ██████  ██    ████  ██  ████  ████  ████████      
██  ██████  ██  ████████  ████  ██████████    ████████
██          ██      ██  ██  ██  ██  ██    ██    ██    
██████████████  ██  ██  ██    ████      ████  ██    ██
                ██  ██      ████████  ██      ██████  
██████      ██        ██████  ██████  ██    ██████████
  ████  ██  ██          ██        ████      ██      ██
██    ██  ████      ██    ██            ██  ██  ██  ██
██            ██        ████████    ██      ██      ██
██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████
STRING

FUNCTION_PATTERN_MODS_QR = <<-STRING.lines
██████████████                                                          ██  ██████████████
██          ██                                                        ██    ██          ██
██  ██████  ██                                                        ██    ██  ██████  ██
██  ██████  ██                                                        ████  ██  ██████  ██
██  ██████  ██                          ██████████                  ██████  ██  ██████  ██
██          ██                          ██      ██                          ██          ██
██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████████
                                        ██      ██                                        
            ██                          ██████████                                        
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
        ██████████                      ██████████                      ██████████        
        ██      ██                      ██      ██                      ██      ██        
        ██  ██  ██                      ██  ██  ██                      ██  ██  ██        
        ██      ██                      ██      ██                      ██      ██        
        ██████████                      ██████████                      ██████████        
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
            ██                                                                            
                                                                                          
        ██  ██                                                                            
  ████████                                                                                
██    ████  ██                          ██████████                      ██████████        
                ██                      ██      ██                      ██      ██        
██████████████                          ██  ██  ██                      ██  ██  ██        
██          ██                          ██      ██                      ██      ██        
██  ██████  ██                          ██████████                      ██████████        
██  ██████  ██                                                                            
██  ██████  ██                                                                            
██          ██                                                                            
██████████████                                                                            
STRING

FUNCTION_PATTERN_MODS_MQR = <<-STRING.lines
██████████████  ██  ██
██          ██        
██  ██████  ██        
██  ██████  ██        
██  ██████  ██        
██          ██        
██████████████        
                      
██                    
                      
██                    
STRING

FUNCTION_PATTERN_MODS_RMQR = <<-STRING.lines
██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████
██          ██  ██    ██                        ██  ██                                              ██  ██                                          ██  ██
██  ██████  ██    ██████                        ██████                                              ██████                                    ████████████
██  ██████  ██  ██████                                                                                                                    ██    ██      ██
██  ██████  ██  ████                            ██████                                              ██████                                  ██████  ██  ██
██          ██  ██████                          ██  ██                                              ██  ██                                ████  ██      ██
██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████
STRING

CODEWORDS_FILL_MODS_QR = <<-STRING.lines
    ██  ██    ████  ██  ██  ██  ████    ██
██████  ██          ████    ████    ██  ██
██  ████      ██  ██    ████    ██  ██  ██
██      ████  ██    ██  ██  ██  ██  ████  
    ██  ██    ████  ██  ██  ██  ████    ██
██████  ██          ████    ████    ██  ██
██  ████      ██  ██    ████    ██  ██  ██
██      ████  ██    ██  ██  ██  ██  ████  
    ██  ██    ██                ████    ██
██████  ██    ██              ██    ██  ██
██  ████                        ██  ██  ██
██      ████                    ██  ████  
    ██  ██    ██                ████    ██
██████  ██                    ██    ██  ██
██  ████      ██                ██  ██  ██
██      ████    ██  ██  ██  ██  ██  ████  
    ██  ██    ██    ████    ██  ████    ██
██████  ██      ████    ████  ██    ██  ██
██  ████        ██  ██  ██  ██  ██  ██  ██
██      ████    ██  ██  ██  ██  ██  ████  
    ██  ██    ██    ████    ██  ████    ██
STRING

CODEWORDS_FILL_MODS_MQR = <<-STRING.lines
  ██  ████    ██    ██
  ██  ██  ██    ████  
  ██████  ██    ██  ██
            ██  ██  ██
  ██        ████    ██
  ██            ████  
  ████      ██  ██  ██
      ████  ██  ██  ██
  ██  ██    ████    ██
  ██  ██  ██    ████  
  ████      ██  ██  ██
STRING
