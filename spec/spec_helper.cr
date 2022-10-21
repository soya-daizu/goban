require "spec"
require "../src/goban"

def convert_bit_stream(bit_stream : Goban::BitStream)
  String.build do |io|
    bit_stream.each do |bit|
      io << (bit ? '1' : '0')
    end
  end
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
  Goban::Segment.bytes("aЉ윇😱"),
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
  Goban::Segment.bytes("012a"),
]
NUMERIC_BYTE_2_STR  = "0123a"
NUMERIC_BYTE_2_SEGS = [
  Goban::Segment.numeric("0123"),
  Goban::Segment.bytes("a"),
]

ALPHANUMERIC_BYTE_1_STR  = "ABCDEa"
ALPHANUMERIC_BYTE_1_SEGS = [
  Goban::Segment.bytes("ABCDEa"),
]
ALPHANUMERIC_BYTE_2_STR  = "ABCDEFa"
ALPHANUMERIC_BYTE_2_SEGS = [
  Goban::Segment.alphanumeric("ABCDEF"),
  Goban::Segment.bytes("a"),
]

SAMPLE_STR  = "こんにちwa、世界！ 123"
SAMPLE_SEGS = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.bytes("wa"),
  Goban::Segment.kanji("、世界！"),
  Goban::Segment.alphanumeric(" 123"),
]

SAMPLE_RESULT_MODS = [
  true, true, true, true, true, true, true, false, false, false, false, true, false, true, false, true, false, false, true, true, true, true, true, true, true,
  true, false, false, false, false, false, true, false, false, false, false, true, true, false, false, true, false, false, true, false, false, false, false, false, true,
  true, false, true, true, true, false, true, false, true, true, true, false, true, false, true, true, false, false, true, false, true, true, true, false, true,
  true, false, true, true, true, false, true, false, true, true, true, false, false, true, false, true, false, false, true, false, true, true, true, false, true,
  true, false, true, true, true, false, true, false, true, false, true, false, false, false, false, false, false, false, true, false, true, true, true, false, true,
  true, false, false, false, false, false, true, false, true, false, false, true, true, false, false, false, false, false, true, false, false, false, false, false, true,
  true, true, true, true, true, true, true, false, true, false, true, false, true, false, true, false, true, false, true, true, true, true, true, true, true,
  false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, true, false, false, false, false, false, false, false, false, false,
  true, false, true, true, true, true, true, false, false, true, false, false, false, true, false, false, true, false, true, true, true, true, true, false, false,
  true, true, true, true, true, true, false, true, false, false, true, false, false, false, false, true, true, false, false, true, false, false, true, true, true,
  false, true, true, false, false, false, true, true, false, true, false, false, true, true, true, false, false, false, true, true, true, true, false, true, true,
  false, false, false, true, true, true, false, true, false, false, true, false, true, false, false, true, false, true, true, true, false, false, false, false, true,
  true, true, true, false, true, false, true, true, true, true, false, true, true, false, true, false, false, false, false, true, true, true, false, false, false,
  true, true, false, false, true, false, false, false, false, true, false, false, false, false, true, true, false, false, true, true, false, true, false, false, true,
  true, false, true, false, true, true, true, false, false, false, false, true, true, false, true, false, false, false, true, false, true, true, true, false, false,
  true, false, true, false, true, false, false, true, false, true, true, true, false, false, true, false, true, false, true, false, false, true, true, true, true,
  true, false, false, true, true, false, true, false, true, false, true, true, false, false, false, false, true, true, true, true, true, false, false, false, false,
  false, false, false, false, false, false, false, false, true, true, true, false, true, true, false, true, true, false, false, false, true, true, false, false, true,
  true, true, true, true, true, true, true, false, false, false, false, false, false, true, false, false, true, false, true, false, true, true, true, false, true,
  true, false, false, false, false, false, true, false, true, false, false, false, true, true, true, true, true, false, false, false, true, true, false, false, true,
  true, false, true, true, true, false, true, false, true, false, true, false, true, true, false, false, true, true, true, true, true, false, false, true, true,
  true, false, true, true, true, false, true, false, true, false, true, false, false, false, false, true, false, true, true, false, false, true, false, false, true,
  true, false, true, true, true, false, true, false, true, true, false, true, true, false, false, true, false, false, true, false, false, false, true, false, true,
  true, false, false, false, false, false, true, false, false, false, true, true, false, false, false, true, false, false, true, false, false, false, true, false, true,
  true, true, true, true, true, true, true, false, true, false, false, true, true, false, false, true, false, false, true, true, false, false, true, false, false,
]

FUNCTION_PATTERN_MODS = [
  true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, true, true, true, true, true, true, true,
  true, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, true, false, false, false, false, false, true,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, true, false, true, true, true, false, true,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, false, true, false, true, true, true, false, true,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, true, true, true, false, true, false, true, true, true, false, true,
  true, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, false, false, true,
  true, true, true, true, true, true, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, false, true, true, true, true, true, true, true,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false,
  false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false,
  false, false, false, false, true, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, true, false, false, false, false,
  false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false,
  false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, false, false, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  false, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  true, false, false, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false,
  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false,
  true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, true, false, false, false, false,
  true, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, true, false, false, false, true, false, false, false, false,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, false, false, false, false,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  true, false, true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  true, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
  true, true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
]

CODEWORDS_FILL_MODS = [
  false, false, true, false, true, false, false, true, true, false, true, false, true, false, true, false, true, true, false, false, true,
  true, true, true, false, true, false, false, false, false, false, true, true, false, false, true, true, false, false, true, false, true,
  true, false, true, true, false, false, false, true, false, true, false, false, true, true, false, false, true, false, true, false, true,
  true, false, false, false, true, true, false, true, false, false, true, false, true, false, true, false, true, false, true, true, false,
  false, false, true, false, true, false, false, true, true, false, true, false, true, false, true, false, true, true, false, false, true,
  true, true, true, false, true, false, false, false, false, false, true, true, false, false, true, true, false, false, true, false, true,
  true, false, true, true, false, false, false, true, false, true, false, false, true, true, false, false, true, false, true, false, true,
  true, false, false, false, true, true, false, true, false, false, true, false, true, false, true, false, true, false, true, true, false,
  false, false, true, false, true, false, false, true, false, false, false, false, false, false, false, false, true, true, false, false, true,
  true, true, true, false, true, false, false, true, false, false, false, false, false, false, false, true, false, false, true, false, true,
  true, false, true, true, false, false, false, false, false, false, false, false, false, false, false, false, true, false, true, false, true,
  true, false, false, false, true, true, false, false, false, false, false, false, false, false, false, false, true, false, true, true, false,
  false, false, true, false, true, false, false, true, false, false, false, false, false, false, false, false, true, true, false, false, true,
  true, true, true, false, true, false, false, false, false, false, false, false, false, false, false, true, false, false, true, false, true,
  true, false, true, true, false, false, false, true, false, false, false, false, false, false, false, false, true, false, true, false, true,
  true, false, false, false, true, true, false, false, true, false, true, false, true, false, true, false, true, false, true, true, false,
  false, false, true, false, true, false, false, true, false, false, true, true, false, false, true, false, true, true, false, false, true,
  true, true, true, false, true, false, false, false, true, true, false, false, true, true, false, true, false, false, true, false, true,
  true, false, true, true, false, false, false, false, true, false, true, false, true, false, true, false, true, false, true, false, true,
  true, false, false, false, true, true, false, false, true, false, true, false, true, false, true, false, true, false, true, true, false,
  false, false, true, false, true, false, false, true, false, false, true, true, false, false, true, false, true, true, false, false, true,
]
