`ifndef CONST
`define CONST

`define HV_DIMENSION			2000
`define DISTANCE_WIDTH			11
`define CHANNEL_WIDTH			2

`define TOTAL_NUM_CHANNEL		214
`define GSR_NUM_CHANNEL			32
`define ECG_NUM_CHANNEL			77
`define EEG_NUM_CHANNEL			105

`define MAX_NUM_CHANNEL			105
`define MAX_NUM_CHANNEL_WIDTH	7

`define NUM_MODALITY			3
`define NUM_MODALITY_WIDTH		3

`define NGRAM_SIZE				3

`define SEED_HV				2000'b10111111101010101011001000111011000100100010110111101111010011011001000110110100000110100010101100101001001000110010000111110000110001010100011111100110011010001100111100100100011101011010001100001100000011000010111110011110100000100110101010010011001010000010000001011111010011100001100000100111110100001111010011110110101111100010100110000000100001001101010011000000011110110001100111011110110010100010101111100001010011111110101111010101010100001110000001111011010101011101001010001011011011100001111101010101110101000000011111010000011110111101011001111001100100100110000010010101010110100111111100111000101001101111101001000010010101111010111111110101010100101001010010001100010010001010011110011101110110111001010110001101001101000001011010011011001010111011110001000101111110100100101110101010010010100111010111000101111100001110111111100101110001100010011000001011110111001101010101111101000110100101110100010010111011001111111010101110101111101111011000001111010010111010110110010001010010101000111110010011111010101100001111011100111000010110010000100110001101101001000010011011100010001000101100000011011011011100101101111001000011101000010001111000111110001111110010100010010010010100110000001110101111101001110011101010101100111110001011101110110110001001101010111111000101111000100010010100110010111110000000011101011111010010000100001010111001000011000000011110100111100111100101100000110100011101001000111111101110100001111010001001111111000101100111111110110101011100010011011101001010011110111001011100100110111100101111101011000110000001010000101100100110100011011101000010110001001100101011001101110000001010100111001010011000100011100101010110001000101000100011111011000010100010100010011111011000110100110101100001011101000100001010101111101001111001010001110010000010000001000101100011110011000010100101001001010101000000011001001001110110101001110010100100011000100100111010101100110111110011101000010101000111010100011101100010001110110000000010111011110110001101110100011010
`define PROTOTYPE_V_PLUS		2000'b10110110101100001100111011010010010111110011011010010100011101100111011000000110101001011100010011011100001001011110010001011100110000010111111100110011010010000110100001111010111010100110110110010011111101001001000111110110100011111100010100100000010101110100100101000111101111100101010011111011010111000100100010110111000000101101101000001111010111010000101100111001001010001111000001100000001101000100000011100001011010111010101101101100010001100101110110000111011110100000111111111100100000010111011001111111110010110101000000001011111000011000001110010010111010100101111000010110011110111010111010100000110110010010011101100011011110010110001010000110011010111011101001000101111100000101110110011100001110111110001100010100100010111000011100011001001101100010000100000110001000100011010010110011001000010011011101000011101111101010000111000001010010001001100110000110101100011101100000010011100110011010010101110010010110001011101001111011100010010000100010110001101011000010100000010011001111000101101010100101010110110111000000110010111110100011110010111000011010011101001111111110011011011100110101011001010000011001110101100110111111000010001111101001001100011010000100011110100100011011100110101001101000110111001001101101010001011010001110011110000100001011101101100010011111011011010100000110101101110101101100000100011110110010011010100010000000000011010111101100111000000010111100100101100111111001000010001111000110010000010101110000001010111000110101100010010111010000010110100000011100000101001010111111101101001100010110100101101101100111100011100111001110101110100010100100100110111001111101100111011101011011101000110000101100101101000101100110000100111110000111001000111010001100111011010010010010101000110010100100001001010010010110101011100111101000101011000101010010101000111100011001010110101111100010010010110110111010000111010111001100010000100100111011001011111111111110101111100100011101010000101100001101010110100100000100001101011010111001000111111001100011011100111000
`define PROTOTYPE_V_MIN			2000'b10110110101100001100111011010110010111110011011010010011011101100100111000000110100111011100010010011100011001011110010001111100110000010111111100110011010010000110100001111010111010100110110110010011111101001001000111110110101010001100010100100000101101110100100101000000101111100110110011110101010111000100100110110111000000101101101000001111010111010000101100111001100010001111000001100000001101000100000011100001011010100010101101101100001101100101110110000111011110100000111111100000100000010111100111111111110010110101111000001011111000011000001110010101111001000101111101001001011110111010101110100000110100010000111100000000011110010110001010000110011010111011101011001001111100001011110110011100001110111111001100010100100010000010011100011001001110100010000100001110001000100011010010110011001100010011011101000011101111101010000101010001010010001001100110000110101100011101100100010011011110010010010101010011110110001011101001111011100111010000100010110001101001100010100000001111001111111101101010101011000110110100000000110011111110100011000010111000011010010010001111000110011011010110000101011110010000011010010101100110111111000010000001101100001100011010000100011110100100010011100110101001101110110101001001101101010000011100010010011110000100001011101101100100100001011011000000011111101110010111101100000100011110111110011010100010000000000011010111101100111000000010111100100101100111000001000011000011000110010000000100000000000010111111110101100010010111010000010110100000011100000101001110111111100011001100010001100101101101100111100010010111101110101110100010100100100110111001011101100111011101011011101000110000101100101100000000000110001000111110000111001000111010001100111011010011010010101011010010100100001001101000010110101011100111110100111011000110110010101000111100011001010110010111100010010011110111111010000111010111001100010000100100111011001001111111110010101111100100011101010000100010001101010110100100011001101110011010111001000011111001100011011100111000
`define PROTOTYPE_A_HIGH		2000'b10110110101100110100111011011110010110110011011010010011011101100100011000000110100111011100010011011101111001011110010010011100110000010111111111010011010011100110100001111110111010100110110110010011111101001001000111110110110011001100010100100000010101110100100101000111101111100110110011010011010111000111000110110111000000101101101000001111010111010000101100111001101010001111000001100000001101000100000011100001011010111010101101101100001101100101110110000111011110100000111111111100100000010111010111111111110010110101111000001011111000011000001110010010111000000101111001010001011110111010111110100000110111010010011101111011011110010110001010000110011010111011101011001001111111101001110110011100001110111111001100010100100010000011011100011001001111100010000100100110001000100011010010110011001100010011011101001011101111101010000100000001010010001001100110000110101100011101111100010011101110010110010101110000110110001011101001111011100111010000100010110001101010000010100000010111001111011101101010101011111110110111000000110011101110100011110010111000011010011111001111111110011011000000110101011001010000011000010101100110111111000010000001101011001100011011100100011110100100001011100110101001101111110111001001100001010001011010010010011110000100001011101101110110011111011011000000000011101111110100101100000100011110110110011010100010000000000011010111101100111000000011011100100101100111111001001010000011000110010000010101110000001010111111110101100010010111010000010110100000011100000101001111111111101101001100010110100101101101100111100010010111101110101110100010100100100110111001111101100111011101011011101000110000101100101101000101100111111000111110000111001000111010001100111011010100010010101011010010100100001001101010010110101011100111111100100111000110110010101000111100011001010110010111100011010010110111111010000111010111001100010000100100111011001101111111100010101111100100011101010000101100001101010110100100011001101101011010111001011011111001111111011100111000
`define PROTOTYPE_A_LOW			2000'b10110100101100001100111011010110010110110011011010010100011101100110001000000110101001011100010011011101001001011110010001011100110001100111111100110011010011000110100001111110111010100110100010010011111101001001000111000110110010000010010100100000010110010100100101000111101111100101010011101001010111000100111110110111000000101101101000001111010111010000101100111001100010001111000001100000001101000100000011101001011010111101101101101100011101100101110110000111011110100000111111111100100000010111101111111111110010110101111000001011111000011000001110010110110111100101111000001110011110111010110110100000110110110011011110000011111110010110001010000110011010111011101011010101111100010100010110011100001110111110101100010100100010111010111100011001001100100010000100100110001000100011010010110011001000010011011101000011101100001010000101000001010010001001100110000110101100011101100000010011011110011010010101110110010110001011101001111011100011010000100010110001101110100010100000011011001111111101101010100101010110110100000000110010111110100011110010111000011010011011001111111110011011011010101101011110010000011001110101111010111111000010001111101000001100011010000100011110100100100011100110101001101000110111001001101101010000011010001110011110000100001011101101101010010111011011011100011111101100010100101100000100011110110001011010100010000000000011010111101100111000000010111100100101100111000001000100001111000110010000010101110000001110111000110101100010010111010000010110100000011100000101001111111111101101001100010110100101101101100111100011110111101110101110100010100100100110111001111101100111011101011011101000110000101100101101010001100110001000111110000111001000111010001100111011010001010010101000110010100100001001101110010110101011100111110100110111000110010010101000111100011001010110101111100010011110110111111010000111010111001100010000100100111011001011111111111110101111100100011101010000101011001101010110100100000100001001011010111001000111111001100011011100111000

`define ceilLog2(x) ( \
(x) > 2**30 ? 31 : \
(x) > 2**29 ? 30 : \
(x) > 2**28 ? 29 : \
(x) > 2**27 ? 28 : \
(x) > 2**26 ? 27 : \
(x) > 2**25 ? 26 : \
(x) > 2**24 ? 25 : \
(x) > 2**23 ? 24 : \
(x) > 2**22 ? 23 : \
(x) > 2**21 ? 22 : \
(x) > 2**20 ? 21 : \
(x) > 2**19 ? 20 : \
(x) > 2**18 ? 19 : \
(x) > 2**17 ? 18 : \
(x) > 2**16 ? 17 : \
(x) > 2**15 ? 16 : \
(x) > 2**14 ? 15 : \
(x) > 2**13 ? 14 : \
(x) > 2**12 ? 13 : \
(x) > 2**11 ? 12 : \
(x) > 2**10 ? 11 : \
(x) > 2**9 ? 10 : \
(x) > 2**8 ? 9 : \
(x) > 2**7 ? 8 : \
(x) > 2**6 ? 7 : \
(x) > 2**5 ? 6 : \
(x) > 2**4 ? 5 : \
(x) > 2**3 ? 4 : \
(x) > 2**2 ? 3 : \
(x) > 2**1 ? 2 : \
(x) > 2**0 ? 1 : 0)

`endif