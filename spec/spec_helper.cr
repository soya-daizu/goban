require "spec"
require "../src/goban"

def convert_bit_stream(bit_stream : Goban::BitStream)
  String.build do |io|
    bit_stream.each do |bit|
      io << (bit ? '1' : '0')
    end
  end
end

def convert_canvas(canvas : Goban::Matrix(UInt8))
  String.build do |io|
    canvas.each_row do |row|
      row.each do |mod|
        io << (mod == 1 ? "██" : "  ")
      end
      io << '\n'
    end
  end.lines
end

ALL_NUMERIC_STR  = "0123456789"
ALL_NUMERIC_SEGS = [
  Goban::Segment.numeric("0123456789"),
]

ALL_ALPHANUMERIC_STR  = "ABCDEF"
ALL_ALPHANUMERIC_SEGS = [
  Goban::Segment.alphanumeric("ABCDEF"),
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

SAMPLE_STR_2 = "こんにちwa"
SAMPLE_SEGS_2 = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.byte("wa"),
]

SAMPLE_RESULT_MODS_QR = <<-STRING
██████████████        ██  ██  ██    ██████████████
██          ██        ████    ██    ██          ██
██  ██████  ██  ██████  ██  ████    ██  ██████  ██
██  ██████  ██  ██████    ██  ██    ██  ██████  ██
██  ██████  ██  ██  ██              ██  ██████  ██
██          ██  ██    ████          ██          ██
██████████████  ██  ██  ██  ██  ██  ██████████████
                ██████████    ██                  
██  ██████████    ██      ██    ██  ██████████    
████████████  ██    ██        ████    ██    ██████
  ████      ████  ██    ██████      ████████  ████
      ██████  ██    ██  ██    ██  ██████        ██
██████  ██  ████████  ████  ██        ██████      
████    ██        ██        ████    ████  ██    ██
██  ██  ██████        ████  ██      ██  ██████    
██  ██  ██    ██  ██████    ██  ██  ██    ████████
██    ████  ██  ██  ████        ██████████        
                ██████  ████  ████      ████    ██
██████████████            ██    ██  ██  ██████  ██
██          ██  ██      ██████████      ████    ██
██  ██████  ██  ██  ██  ████    ██████████    ████
██  ██████  ██  ██  ██        ██  ████    ██    ██
██  ██████  ██  ████  ████    ██    ██      ██  ██
██          ██      ████      ██    ██      ██  ██
██████████████  ██    ████    ██    ████    ██    
STRING
  .lines

SAMPLE_RESULT_MODS_MQR = <<-STRING
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
  .lines

SAMPLE_RESULT_MODS_RMQR = <<-STRING
██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██████
██          ██        ████  ██████  ██  ██  ██  ██  ██
██  ██████  ██  ████          ██      ██  ████  ██  ██
██  ██████  ██    ████      ████  ████  ████████      
██  ██████  ██  ████████  ████  ██████████    ████████
██          ██      ██████  ██  ██  ██    ██    ██    
██████████████  ██████  ██    ████      ████  ██    ██
                    ████████████████  ██      ██████  
████  ██████      ████        ██████  ██    ██████████
  ██  ██    ██████  ██  ████      ████      ██      ██
██    ██  ██████████  ██  ██            ██  ██  ██  ██
██      ██    ██    ████      ██    ██      ██      ██
██████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████
STRING
  .lines

FUNCTION_PATTERN_MODS_QR = <<-STRING
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
  .lines

FUNCTION_PATTERN_MODS_MQR = <<-STRING
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
  .lines

CODEWORDS_FILL_MODS_QR = <<-STRING
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
  .lines

CODEWORDS_FILL_MODS_MQR = <<-STRING
  ██  ████    ██    ██
  ██  ██  ██    ██  ██
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
  .lines
