`ifndef CONST
`define CONST

`define HV_DIMENSION			2000
`define DISTANCE_WIDTH			11
`define CHANNEL_WIDTH			2

`define TOTAL_NUM_CHANNEL		214
`define GSR_NUM_CHANNEL			32
`define ECG_NUM_CHANNEL			77
`define EEG_NUM_CHANNEL			105

`define HALF_GSR_NUM_CHANNEL    16
`define HALF_ECG_NUM_CHANNEL    39
`define HALF_EEG_NUM_CHANNEL    53

`define MAX_NUM_CHANNEL			105
`define MAX_NUM_CHANNEL_WIDTH	7
`define MAX_HALF_NUM_CHANNEL_WIDTH  6

`define NUM_MODALITY			3
`define NUM_MODALITY_WIDTH		3

`define NGRAM_SIZE				3

`define SEED_HV				2000'b10111111101010101011001000111011000100100010110111101111010011011001000110110100000110100010101100101001001000110010000111110000110001010100011111100110011010001100111100100100011101011010001100001100000011000010111110011110100000100110101010010011001010000010000001011111010011100001100000100111110100001111010011110110101111100010100110000000100001001101010011000000011110110001100111011110110010100010101111100001010011111110101111010101010100001110000001111011010101011101001010001011011011100001111101010101110101000000011111010000011110111101011001111001100100100110000010010101010110100111111100111000101001101111101001000010010101111010111111110101010100101001010010001100010010001010011110011101110110111001010110001101001101000001011010011011001010111011110001000101111110100100101110101010010010100111010111000101111100001110111111100101110001100010011000001011110111001101010101111101000110100101110100010010111011001111111010101110101111101111011000001111010010111010110110010001010010101000111110010011111010101100001111011100111000010110010000100110001101101001000010011011100010001000101100000011011011011100101101111001000011101000010001111000111110001111110010100010010010010100110000001110101111101001110011101010101100111110001011101110110110001001101010111111000101111000100010010100110010111110000000011101011111010010000100001010111001000011000000011110100111100111100101100000110100011101001000111111101110100001111010001001111111000101100111111110110101011100010011011101001010011110111001011100100110111100101111101011000110000001010000101100100110100011011101000010110001001100101011001101110000001010100111001010011000100011100101010110001000101000100011111011000010100010100010011111011000110100110101100001011101000100001010101111101001111001010001110010000010000001000101100011110011000010100101001001010101000000011001001001110110101001110010100100011000100100111010101100110111110011101000010101000111010100011101100010001110110000000010111011110110001101110100011010
`define PROTOTYPE_V_PLUS    2000'b00111011010010110000110101010010010100111110111001110100011000101111000111101010100111101010010010001111110001011110100001100100010100010111111100100100010100011101011100000000111011011011010101001010000100111100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001110001111000101100111111001111011001010111010011111010100000010110110010111010001000001100000100111011010111110001100110010101011110101100001111101011110011100011100100001101111000111111101100000001101110010111011110001110001001100100111001000101011101110010110111110010100001011011101101101010100101000100110001010000101011111111101010011010101011100001111000010100011010111110000101010000000100010101110110100011011010011001001000100011011111000110111001001100100001111000110111011110011010011100111000111110000001010001110001000110011000011011111100000010001110110010101011010101000000101010001011101001100110000010010111100010000111110101010001011000010101001111001110100000100101100101100010011010001111001001100101010100000110101101100010000111110100000011101100000011100101101100010101100101001101100001101000010010011011010001010011000100100110010100000111100100101111001000001011011001101010010001011011110111001101001010001000000111111110110100011011001001111010101110010101101000011100011110111111010010101101001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101110001111011001010111001010110010000111001111001010000011011010111110000000001101101001100001010100100000001100011001100101001001011000100000010100011000010111111010001100111111000110100001000011010000100101010011001101000011010110000001001010101001111100000111001000001110000000000110111011011011100101100001000000000001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010100100111100000101100000000110101010110010101010110110000011011111110110110110010000101010010100110000101011010010111101111101000000000
`define PROTOTYPE_V_MIN     2000'b00111011010001110000110100100010010100011110111000010100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010101111101011100000000000011011011010101001010000100010100011110110000000101110100010010000111001111110011011100110000110101001101010011111011010100110110100001110111011100110001001011111000101100111111001111011001010001010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000101001110010111011110001110001001111100011000110101011101110010110111010010100111011000001101101001000100101000110001010101011010111000101010011010101011100001111000010100011010111110000101011100010100101101110110100011011010011001001000101101011111000110100010101100100001100000110111011110000000011100111000111110000001010001110001000110011000011011111100000010010010110010101011010110101010110110001011101001100110000000010111100010000111110101110001011000001001001111110110100000100101100101100010011010001111001001100101010100000110101101100010000000110100010011001100000000000101101100010101100101110101100001101000010010011011010001010010001010011110010100000111100100101111001000001101011001101010010000011011100111001010001010001000000111111010110000011110001001111011011110010101101000011100011110111110100010101101001111001101101001100011110001011001110011010101111011100101010111011001011101001000101100000001111011001010111001001101010000111001110111011110011011010111110000000001101101001100001101100100110001100011001100101001011011000100000010010011000010111111010001100111111000110100001000011010010100101010011001101000011011100000001001010101001111000000111001000101110000110001110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101111110110000101000000010000111010000010000100111100000101100000001000101010110010101010110110000011010001110110110101010000101010010101000000101011010010111101111101011110001
`define PROTOTYPE_A_HIGH    2000'b00111011010010101000110100100010010110011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100000100010100011101011100000000111011011011010101001010000100011100011110110000000101110100010010000111001101110011011100110000110001001101010011111011110100110101000001110111011100110001001101111000101100111111000001011001011111010011111010100000010001110010111010001000001101000110111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000001101110010111011110001110010101100111111001000101011101110010110111000010100110011000001101101010100101011000110001010101011000111000101010011001001011100001111000010100011010111110000101101100000100101101110110100011011010011001001000101101011000000110100001001100100101001000110111000010101010011100111000111100000001010001110001000110011000011011111100010110001110110010101011010110101000101010001011101001100110000010010111100010000111110001010001011001100101001111001110100000100101100101100010011010001111001001100101010000000110101101100010000000110100001100001100000011100101101100010101100101110001100001101000011010011011010001010011001100111110010100000111100100101111001000001101011001101010010000011011101011001010001010001000000111111010110011011011001001111011101110010101101000011100011110111110010010101101001111001101101001100011101101011001110011010100001011100101010111011011011101001000101101110011111011001010111001001001010000111001111011010000011011010111110000000001101101001100001010100100110001100011001100101001011011000100000010100011000010111111010001100111111000110100101000011010010100101010011001101000011101110000001001010101001111000000111001000001010001000000110111011011011100101100001000000000001000001111101011001100010111111011011100011010101011101010110101110110110000101000000010000111010000010100100111100000101100000001010110110110010101010110110000011010001110110110001010000101010010100110000101011010010111101111101011110000
`define PROTOTYPE_A_LOW     2000'b00111011010001110000110100100010010100011110111001110100011000101111000111101010100111101010010010001111110001011111100001100100010101100111111100110100010101101101011100000000000011011011010101001010000100001100011110110000000101110100010010000111001101110011011100110000101101001101010011111011110100110101000001110111011100110001100101111000101100111111001111011001010111010011111010100000010110110010111010001000001111000000111011010111110001100110010101011110101101001111101011101111100011100100001101111000111111101100000011101110010111011110001110001001111100111001000101011101110010110111000010100001011001001101101010100101001000110001011110101010111111101010011010101011100001111000010100011010111110000101001100010100010101110110100011011010011001001000100011011111000110111001001100100001110000110111011110011010011100111000111110000001010001110001000110011000011011111100000010000110110010101011010110100110110110001011101001100110000010010111100010000111110101110001011000010101001111000110100000100101100101100010011010001111001001100101010000000110101101100010000000110100010011101100000000000101101100010101100101101101100001101000010010011011010001010010001010000110010100000111100100101111001000001011011001101010010000011011110111001101001010001000000111111010110100011011111001111011101110010101101000011100011110111111010010101011001111001101101001100011101101011001110011010101111011100101010111011001011101001000101101101101111011001010111001010110010000111001111011011110011011010111110000000001101101001100001010100100110001100011001100101001011011000100000011010011000010111111010001100111111000110100010100011010010100101010011001101000011010110000001001010101001111100000111001000101110000110001110111011011011100101100001000000001001000001100001011001100010111111011011100011010101011101010110101111110110000101000000000000111010000010000100111100000101100000000100101010110010101010110110000011101001110110110001010000101010010101110000101011010010111101111101000001001

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