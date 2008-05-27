#line 1 "sendero/view/expression/Compile.rl"
module sendero.view.expression.Compile;

import sendero_base.Core;
import sendero.vm.Expression;

import sendero_base.util.collection.Stack;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout;

void error(char[] msg)
{
	throw new Exception(msg);
}

interface ExprBuilder
{
	Expression end();
}

class BinaryBuilder : ExprBuilder
{
	Expression end() { return null; }
}

#line 182 "sendero/view/expression/Compile.rl"



#line 31 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	10, 1, 12, 1, 13, 2, 0, 10, 
	2, 1, 9, 2, 2, 11, 2, 6, 
	5, 2, 7, 10, 2, 8, 10, 2, 
	10, 12, 2, 10, 13, 2, 12, 13, 
	3, 0, 2, 11, 3, 1, 9, 13, 
	3, 2, 11, 13, 3, 4, 2, 11, 
	3, 5, 2, 11, 3, 6, 1, 9, 
	3, 6, 2, 11, 3, 7, 1, 9, 
	3, 7, 2, 11, 3, 8, 1, 9, 
	3, 8, 2, 11, 3, 10, 2, 11, 
	3, 10, 12, 13, 4, 1, 9, 2, 
	11, 4, 1, 9, 12, 13, 4, 2, 
	11, 12, 13, 4, 10, 2, 11, 13, 
	5, 1, 9, 2, 11, 13, 5, 10, 
	2, 11, 12, 13, 6, 1, 9, 2, 
	11, 12, 13
];

static const short[] _sendero_view_compile_key_offsets = [
	0, 0, 23, 24, 26, 29, 33, 56, 
	59, 82, 83, 85, 88, 111, 134, 139, 
	144, 167, 177, 182, 202, 225, 229, 234, 
	243, 248, 268, 291, 295, 302, 306, 327, 
	350, 352, 352, 376, 399, 402, 404, 411, 
	414, 437, 441, 464, 469, 479, 498, 516, 
	536, 546, 553, 576, 581, 601, 621, 626, 
	648, 656, 661, 684, 690, 709, 729, 735, 
	743, 749, 768, 788, 798, 805
];

static const char[] _sendero_view_compile_trans_keys = [
	32u, 33u, 34u, 37u, 39u, 40u, 41u, 47u, 
	60u, 61u, 62u, 93u, 96u, 9u, 13u, 42u, 
	45u, 48u, 57u, 65u, 90u, 95u, 122u, 61u, 
	34u, 92u, 34u, 39u, 92u, 34u, 39u, 92u, 
	96u, 32u, 33u, 34u, 37u, 40u, 41u, 47u, 
	60u, 61u, 62u, 92u, 93u, 96u, 9u, 13u, 
	39u, 45u, 48u, 57u, 65u, 90u, 95u, 122u, 
	39u, 92u, 96u, 32u, 33u, 34u, 37u, 39u, 
	40u, 41u, 47u, 60u, 61u, 62u, 93u, 96u, 
	9u, 13u, 42u, 45u, 48u, 57u, 65u, 90u, 
	95u, 122u, 96u, 61u, 96u, 34u, 92u, 96u, 
	32u, 33u, 34u, 37u, 40u, 41u, 47u, 60u, 
	61u, 62u, 92u, 93u, 95u, 9u, 13u, 39u, 
	45u, 48u, 57u, 65u, 90u, 97u, 122u, 32u, 
	33u, 34u, 37u, 40u, 41u, 47u, 60u, 61u, 
	62u, 92u, 93u, 96u, 9u, 13u, 39u, 45u, 
	48u, 57u, 65u, 90u, 95u, 122u, 34u, 39u, 
	61u, 92u, 96u, 34u, 46u, 92u, 48u, 57u, 
	32u, 33u, 34u, 37u, 40u, 41u, 47u, 62u, 
	92u, 93u, 96u, 9u, 13u, 39u, 45u, 48u, 
	57u, 60u, 61u, 65u, 90u, 95u, 122u, 34u, 
	39u, 92u, 96u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 40u, 46u, 91u, 92u, 32u, 33u, 
	34u, 40u, 41u, 46u, 91u, 92u, 93u, 95u, 
	9u, 13u, 48u, 57u, 60u, 61u, 65u, 90u, 
	97u, 122u, 32u, 33u, 34u, 37u, 40u, 41u, 
	47u, 62u, 92u, 93u, 96u, 9u, 13u, 39u, 
	45u, 48u, 57u, 60u, 61u, 65u, 90u, 95u, 
	122u, 39u, 61u, 92u, 96u, 39u, 46u, 92u, 
	48u, 57u, 39u, 92u, 96u, 48u, 57u, 65u, 
	90u, 95u, 122u, 39u, 40u, 46u, 91u, 92u, 
	32u, 33u, 34u, 39u, 40u, 41u, 46u, 91u, 
	93u, 95u, 9u, 13u, 48u, 57u, 60u, 61u, 
	65u, 90u, 97u, 122u, 32u, 33u, 34u, 37u, 
	39u, 40u, 41u, 47u, 62u, 93u, 96u, 9u, 
	13u, 42u, 45u, 48u, 57u, 60u, 61u, 65u, 
	90u, 95u, 122u, 46u, 96u, 48u, 57u, 96u, 
	48u, 57u, 65u, 90u, 95u, 122u, 40u, 46u, 
	91u, 96u, 32u, 33u, 34u, 39u, 40u, 41u, 
	46u, 47u, 91u, 93u, 96u, 9u, 13u, 48u, 
	57u, 60u, 61u, 65u, 90u, 95u, 122u, 32u, 
	33u, 34u, 37u, 39u, 40u, 41u, 47u, 62u, 
	93u, 96u, 9u, 13u, 42u, 45u, 48u, 57u, 
	60u, 61u, 65u, 90u, 95u, 122u, 39u, 92u, 
	32u, 33u, 34u, 37u, 39u, 40u, 41u, 42u, 
	47u, 60u, 61u, 62u, 93u, 96u, 9u, 13u, 
	43u, 45u, 48u, 57u, 65u, 90u, 95u, 122u, 
	32u, 33u, 34u, 37u, 39u, 40u, 41u, 47u, 
	60u, 61u, 62u, 93u, 96u, 9u, 13u, 42u, 
	45u, 48u, 57u, 65u, 90u, 95u, 122u, 46u, 
	48u, 57u, 61u, 62u, 95u, 48u, 57u, 65u, 
	90u, 97u, 122u, 40u, 46u, 91u, 32u, 33u, 
	34u, 37u, 40u, 41u, 47u, 60u, 61u, 62u, 
	92u, 93u, 96u, 9u, 13u, 42u, 45u, 48u, 
	57u, 65u, 90u, 95u, 122u, 34u, 39u, 61u, 
	92u, 32u, 33u, 34u, 37u, 40u, 41u, 47u, 
	62u, 92u, 93u, 95u, 9u, 13u, 39u, 45u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	34u, 39u, 92u, 61u, 62u, 34u, 39u, 92u, 
	95u, 48u, 57u, 65u, 90u, 97u, 122u, 32u, 
	33u, 40u, 41u, 46u, 91u, 92u, 93u, 95u, 
	9u, 13u, 48u, 57u, 60u, 61u, 65u, 90u, 
	97u, 122u, 32u, 33u, 40u, 41u, 46u, 92u, 
	93u, 95u, 9u, 13u, 48u, 57u, 60u, 61u, 
	65u, 90u, 97u, 122u, 32u, 34u, 37u, 40u, 
	41u, 47u, 60u, 62u, 92u, 96u, 9u, 13u, 
	39u, 45u, 48u, 57u, 65u, 90u, 95u, 122u, 
	34u, 46u, 92u, 95u, 48u, 57u, 65u, 90u, 
	97u, 122u, 34u, 40u, 46u, 91u, 92u, 48u, 
	57u, 32u, 33u, 34u, 37u, 40u, 41u, 47u, 
	60u, 61u, 62u, 92u, 93u, 95u, 9u, 13u, 
	39u, 45u, 48u, 57u, 65u, 90u, 97u, 122u, 
	39u, 92u, 96u, 61u, 62u, 32u, 33u, 34u, 
	39u, 40u, 41u, 46u, 47u, 93u, 96u, 9u, 
	13u, 48u, 57u, 60u, 61u, 65u, 90u, 95u, 
	122u, 32u, 34u, 37u, 39u, 40u, 41u, 47u, 
	60u, 62u, 96u, 9u, 13u, 42u, 45u, 48u, 
	57u, 65u, 90u, 95u, 122u, 34u, 40u, 46u, 
	91u, 92u, 32u, 33u, 34u, 39u, 40u, 41u, 
	42u, 46u, 47u, 91u, 93u, 96u, 9u, 13u, 
	48u, 57u, 60u, 61u, 65u, 90u, 95u, 122u, 
	46u, 95u, 48u, 57u, 65u, 90u, 97u, 122u, 
	40u, 46u, 91u, 48u, 57u, 32u, 33u, 34u, 
	37u, 40u, 41u, 47u, 60u, 61u, 62u, 92u, 
	93u, 96u, 9u, 13u, 42u, 45u, 48u, 57u, 
	65u, 90u, 95u, 122u, 34u, 39u, 92u, 96u, 
	61u, 62u, 32u, 33u, 34u, 39u, 40u, 41u, 
	46u, 93u, 95u, 9u, 13u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	39u, 40u, 41u, 47u, 60u, 62u, 96u, 9u, 
	13u, 42u, 45u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 40u, 46u, 91u, 92u, 96u, 46u, 
	96u, 48u, 57u, 65u, 90u, 95u, 122u, 40u, 
	46u, 91u, 96u, 48u, 57u, 32u, 33u, 34u, 
	40u, 41u, 46u, 92u, 93u, 95u, 9u, 13u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	32u, 34u, 37u, 40u, 41u, 47u, 60u, 62u, 
	92u, 96u, 9u, 13u, 39u, 45u, 48u, 57u, 
	65u, 90u, 95u, 122u, 39u, 46u, 92u, 95u, 
	48u, 57u, 65u, 90u, 97u, 122u, 39u, 40u, 
	46u, 91u, 92u, 48u, 57u, 96u, 61u, 62u, 
	0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 13, 1, 2, 3, 4, 13, 3, 
	13, 1, 2, 3, 13, 13, 5, 3, 
	11, 4, 5, 10, 11, 4, 3, 3, 
	5, 10, 11, 2, 1, 4, 11, 11, 
	2, 0, 14, 13, 1, 0, 1, 3, 
	13, 4, 11, 3, 4, 9, 8, 10, 
	4, 5, 13, 3, 10, 10, 5, 12, 
	2, 3, 13, 4, 9, 10, 6, 2, 
	4, 9, 10, 4, 5, 1
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 5, 0, 0, 0, 0, 5, 0, 
	5, 0, 0, 0, 5, 5, 0, 1, 
	6, 3, 0, 5, 6, 0, 1, 3, 
	0, 5, 6, 1, 3, 0, 5, 6, 
	0, 0, 5, 5, 1, 1, 3, 0, 
	5, 0, 6, 1, 3, 5, 5, 5, 
	3, 1, 5, 1, 5, 5, 0, 5, 
	3, 1, 5, 1, 5, 5, 0, 3, 
	1, 5, 5, 3, 1, 1
];

static const short[] _sendero_view_compile_index_offsets = [
	0, 0, 19, 21, 24, 28, 33, 52, 
	56, 75, 77, 80, 84, 103, 122, 128, 
	133, 151, 159, 165, 181, 199, 204, 209, 
	216, 222, 238, 256, 260, 265, 270, 287, 
	305, 308, 309, 329, 348, 351, 353, 358, 
	362, 381, 386, 404, 409, 417, 432, 446, 
	462, 470, 477, 496, 501, 517, 533, 539, 
	557, 563, 568, 587, 593, 608, 624, 631, 
	637, 643, 658, 674, 682, 689
];

static const ubyte[] _sendero_view_compile_indicies = [
	0, 2, 3, 4, 5, 6, 7, 8, 
	10, 11, 4, 13, 14, 0, 4, 9, 
	12, 12, 1, 4, 1, 16, 17, 15, 
	19, 20, 21, 18, 19, 20, 21, 20, 
	18, 23, 24, 18, 19, 25, 26, 19, 
	28, 29, 19, 31, 32, 19, 23, 19, 
	27, 30, 30, 22, 33, 31, 19, 22, 
	34, 35, 36, 33, 22, 37, 38, 33, 
	40, 41, 33, 43, 33, 34, 33, 39, 
	42, 42, 14, 4, 14, 33, 4, 14, 
	19, 44, 45, 18, 46, 47, 20, 20, 
	48, 49, 20, 51, 52, 20, 21, 54, 
	53, 46, 20, 50, 53, 53, 18, 46, 
	47, 20, 20, 48, 49, 20, 51, 52, 
	20, 21, 54, 20, 46, 20, 50, 53, 
	53, 18, 19, 20, 20, 21, 20, 18, 
	56, 57, 58, 57, 55, 46, 47, 20, 
	20, 48, 49, 20, 20, 21, 54, 20, 
	46, 20, 50, 51, 53, 53, 18, 60, 
	61, 63, 61, 62, 62, 62, 59, 65, 
	66, 67, 68, 69, 64, 70, 71, 64, 
	72, 73, 74, 77, 78, 79, 76, 70, 
	75, 71, 76, 76, 65, 23, 24, 18, 
	19, 25, 26, 19, 19, 31, 32, 19, 
	23, 19, 27, 28, 30, 30, 22, 33, 
	19, 31, 19, 22, 80, 81, 82, 81, 
	56, 84, 86, 60, 85, 85, 85, 83, 
	87, 88, 74, 77, 78, 65, 89, 90, 
	91, 65, 92, 93, 94, 97, 98, 96, 
	89, 95, 90, 96, 96, 87, 34, 35, 
	36, 33, 22, 37, 38, 33, 33, 43, 
	33, 34, 33, 39, 40, 42, 42, 14, 
	99, 100, 99, 80, 103, 102, 102, 102, 
	101, 104, 94, 97, 105, 87, 106, 107, 
	108, 109, 110, 111, 112, 113, 116, 117, 
	87, 106, 114, 107, 115, 115, 105, 0, 
	2, 3, 4, 5, 6, 7, 8, 4, 
	13, 14, 0, 4, 9, 10, 12, 12, 
	1, 33, 31, 22, 1, 0, 2, 3, 
	4, 5, 6, 7, 118, 8, 10, 11, 
	4, 13, 14, 0, 4, 9, 12, 12, 
	1, 0, 2, 3, 4, 5, 6, 7, 
	8, 10, 11, 4, 13, 14, 0, 4, 
	9, 12, 12, 119, 120, 120, 100, 4, 
	1, 122, 122, 122, 122, 121, 123, 112, 
	116, 105, 124, 125, 45, 45, 126, 127, 
	45, 128, 129, 45, 17, 54, 18, 124, 
	45, 50, 130, 130, 15, 19, 20, 20, 
	21, 18, 46, 47, 20, 20, 48, 49, 
	20, 20, 21, 54, 53, 46, 20, 50, 
	51, 53, 53, 18, 19, 20, 21, 20, 
	18, 60, 61, 63, 62, 62, 62, 62, 
	59, 131, 132, 133, 134, 67, 68, 69, 
	137, 136, 131, 135, 132, 136, 136, 64, 
	138, 139, 140, 141, 57, 58, 143, 142, 
	138, 50, 139, 142, 142, 55, 144, 61, 
	61, 145, 146, 61, 61, 61, 63, 61, 
	144, 61, 147, 53, 53, 59, 149, 150, 
	153, 152, 151, 152, 152, 148, 155, 156, 
	157, 159, 160, 158, 154, 23, 24, 18, 
	19, 25, 26, 19, 28, 29, 19, 31, 
	32, 30, 23, 19, 27, 30, 30, 22, 
	33, 31, 19, 19, 22, 161, 162, 163, 
	164, 165, 166, 120, 167, 169, 80, 161, 
	9, 162, 168, 168, 100, 170, 171, 103, 
	83, 172, 173, 174, 103, 103, 101, 170, 
	103, 175, 12, 12, 121, 109, 177, 178, 
	179, 180, 176, 106, 107, 108, 109, 110, 
	111, 181, 112, 113, 116, 117, 87, 106, 
	114, 107, 115, 115, 105, 183, 185, 184, 
	185, 185, 182, 187, 188, 190, 189, 186, 
	46, 47, 20, 20, 48, 49, 20, 51, 
	52, 20, 44, 54, 20, 46, 20, 50, 
	53, 53, 18, 19, 20, 21, 20, 20, 
	18, 191, 192, 193, 56, 194, 195, 99, 
	197, 196, 191, 39, 192, 196, 196, 80, 
	198, 199, 84, 83, 200, 201, 84, 84, 
	84, 84, 198, 84, 202, 42, 42, 101, 
	65, 66, 67, 68, 203, 176, 64, 205, 
	182, 206, 207, 207, 204, 209, 210, 212, 
	186, 211, 208, 213, 214, 55, 215, 216, 
	81, 82, 218, 217, 213, 27, 214, 217, 
	217, 56, 219, 59, 60, 220, 221, 60, 
	60, 60, 86, 60, 219, 60, 222, 30, 
	30, 83, 204, 223, 226, 225, 224, 225, 
	225, 149, 208, 227, 228, 230, 231, 229, 
	155, 4, 33, 14, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	1, 0, 2, 3, 1, 32, 1, 33, 
	34, 36, 31, 37, 38, 39, 9, 4, 
	50, 4, 5, 6, 13, 5, 7, 6, 
	21, 6, 7, 22, 20, 51, 23, 7, 
	24, 8, 8, 10, 11, 8, 9, 27, 
	26, 69, 28, 29, 5, 12, 13, 14, 
	13, 5, 15, 16, 59, 17, 18, 13, 
	6, 15, 13, 18, 19, 45, 17, 18, 
	13, 6, 13, 13, 13, 13, 6, 20, 
	6, 6, 6, 65, 66, 6, 6, 19, 
	8, 22, 6, 24, 25, 23, 24, 8, 
	6, 8, 26, 58, 8, 8, 8, 60, 
	61, 8, 25, 27, 1, 29, 28, 30, 
	8, 1, 1, 31, 40, 50, 1, 1, 
	1, 34, 52, 53, 1, 30, 35, 33, 
	36, 39, 38, 1, 12, 41, 12, 4, 
	42, 43, 44, 13, 16, 13, 13, 46, 
	47, 45, 13, 16, 13, 13, 47, 45, 
	45, 45, 18, 48, 45, 19, 49, 48, 
	47, 45, 13, 6, 13, 46, 46, 13, 
	13, 1, 31, 40, 50, 1, 1, 34, 
	53, 30, 30, 54, 30, 39, 55, 56, 
	12, 12, 12, 12, 12, 35, 30, 57, 
	56, 53, 1, 1, 52, 52, 1, 8, 
	26, 58, 8, 8, 61, 25, 25, 62, 
	25, 29, 63, 13, 25, 64, 63, 61, 
	8, 8, 60, 60, 8, 6, 20, 6, 
	6, 66, 19, 19, 19, 24, 67, 68, 
	67, 66, 19, 6, 65, 65, 6, 6
];

static const ubyte[] _sendero_view_compile_trans_actions = [
	13, 0, 0, 0, 0, 0, 9, 11, 
	0, 1, 0, 0, 1, 0, 0, 0, 
	0, 17, 0, 0, 0, 45, 0, 13, 
	0, 9, 11, 1, 0, 0, 1, 19, 
	0, 0, 13, 0, 0, 9, 11, 1, 
	0, 0, 1, 0, 17, 0, 13, 0, 
	9, 11, 1, 0, 0, 1, 0, 27, 
	27, 0, 110, 24, 24, 24, 0, 105, 
	15, 15, 7, 3, 5, 96, 36, 15, 
	30, 33, 3, 21, 21, 5, 42, 15, 
	27, 0, 56, 24, 24, 0, 52, 15, 
	7, 36, 15, 15, 30, 33, 3, 21, 
	21, 5, 15, 0, 27, 24, 0, 24, 
	7, 15, 36, 15, 15, 15, 30, 33, 
	3, 15, 21, 21, 5, 15, 0, 0, 
	0, 24, 0, 7, 13, 0, 9, 11, 
	0, 0, 1, 36, 15, 30, 33, 21, 
	21, 15, 88, 27, 72, 80, 48, 27, 
	84, 68, 76, 1, 100, 100, 24, 0, 
	27, 132, 92, 92, 64, 3, 15, 60, 
	126, 88, 27, 27, 27, 72, 80, 27, 
	48, 27, 84, 24, 68, 76, 24, 1, 
	15, 7, 3, 5, 39, 15, 100, 24, 
	0, 27, 92, 64, 3, 15, 60, 88, 
	27, 27, 72, 80, 48, 27, 84, 24, 
	68, 76, 1, 39, 100, 24, 0, 27, 
	92, 64, 3, 15, 60, 88, 27, 72, 
	80, 48, 27, 84, 68, 76, 1, 24, 
	0, 27, 120, 64, 3, 15, 60, 115
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 70;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;
static const int sendero_view_compile_en_main_Expression_end_call = 39;

#line 185 "sendero/view/expression/Compile.rl"


struct ExprState
{
	enum { None = 0, Access, Binary };
	int state = None;
	
	union
	{
		VarAccess acc;
		BinaryExpression binary;
	}
}
alias ExprState State;

class Fsm
{
	this()
	{
		exprStack = new Stack!(ExprState);
	}

	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
	enum ParenExpr { None, Expr, Func }; 
	ParenExpr parenExpr;
	ExprState cur;
	Stack!(ExprState) exprStack;
}

void parse(char[] src)
{
	auto fsm = new Fsm;
	char* p = src.ptr;
	char* pe = p + src.length + 1;
	char* eof = pe;
	
#line 405 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 224 "sendero/view/expression/Compile.rl"
	
#line 409 "sendero/view/expression/Compile.d"
	{
	int _klen;
	uint _trans;
	byte* _acts;
	uint _nacts;
	char* _keys;

	if ( p == pe )
		goto _test_eof;
	if (  fsm.cs == 0 )
		goto _out;
_resume:
	_keys = &_sendero_view_compile_trans_keys[_sendero_view_compile_key_offsets[ fsm.cs]];
	_trans = _sendero_view_compile_index_offsets[ fsm.cs];

	_klen = _sendero_view_compile_single_lengths[ fsm.cs];
	if ( _klen > 0 ) {
		char* _lower = _keys;
		char* _mid;
		char* _upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _sendero_view_compile_range_lengths[ fsm.cs];
	if ( _klen > 0 ) {
		char* _lower = _keys;
		char* _mid;
		char* _upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += ((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _sendero_view_compile_indicies[_trans];
	 fsm.cs = _sendero_view_compile_trans_targs[_trans];

	if ( _sendero_view_compile_trans_actions[_trans] == 0 )
		goto _again;

	_acts = &_sendero_view_compile_actions[_sendero_view_compile_trans_actions[_trans]];
	_nacts = cast(uint) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 32 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p;}
	break;
	case 1:
#line 34 "sendero/view/expression/Compile.rl"
	{
	auto token = fsm.tokenStart[0 .. p - fsm.tokenStart];
	
	debug Stdout.formatln("Found identifier: {}", token);
	
	Var var;
	var.type = VarT.String;
	var.string_ = token;
	auto step = new Literal(var);
	
	switch(fsm.cur.state)
	{
	case State.Access:
		fsm.cur.acc.accessSteps ~= step;
		break;
	case State.None:
		fsm.cur.state = State.Access;
		fsm.cur.acc = new VarAccess;
		fsm.cur.acc.accessSteps ~= step;
		break;
	default:
		error(`Unexpected identifier "` ~ token ~ `"`);
		break;
	}		
}
	break;
	case 2:
#line 60 "sendero/view/expression/Compile.rl"
	{ Stdout.formatln("Found number: {}", fsm.tokenStart[0 .. p - fsm.tokenStart]); }
	break;
	case 3:
#line 62 "sendero/view/expression/Compile.rl"
	{
 	if(fsm.cur.state != State.Access)
 		error(`Unexpected token "."`);
	debug Stdout("Found dot step").newline;
}
	break;
	case 4:
#line 67 "sendero/view/expression/Compile.rl"
	{ Stdout("Found index step").newline; }
	break;
	case 5:
#line 68 "sendero/view/expression/Compile.rl"
	{ fsm.parenExpr = Fsm.ParenExpr.Func; Stdout("Found function call").newline; }
	break;
	case 6:
#line 70 "sendero/view/expression/Compile.rl"
	{ fsm.parenExpr = Fsm.ParenExpr.Expr; }
	break;
	case 7:
#line 71 "sendero/view/expression/Compile.rl"
	{
		auto paren = fsm.parenExpr;
		fsm.parenExpr = Fsm.ParenExpr.None;
		switch(paren)
		{
		case Fsm.ParenExpr.Expr:
		case Fsm.ParenExpr.Func:
			{ fsm.cs = 39; if (true) goto _again;}
		default:
			error("Missing opening parentheses");
			break;
		}
}
	break;
	case 8:
#line 85 "sendero/view/expression/Compile.rl"
	{
	/+if(fsm.cur.state) {
		fsm.exprStack.push(fsm.cur);
		fsm.cur.state = State.None;
		debug Stdout("Found space").newline;
	}+/
}
	break;
	case 9:
#line 135 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 10:
#line 145 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 11:
#line 150 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 12:
#line 155 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 13:
#line 162 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
#line 570 "sendero/view/expression/Compile.d"
		default: break;
		}
	}

_again:
	if (  fsm.cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}
#line 225 "sendero/view/expression/Compile.rl"
}

debug(SenderoUnittest)
{

unittest
{
	parse("x + y");

	parse("test.one[test2]  test3(param1) /*a comment*/ test4[step](param2)[5]['a str'] ");
	
	bool caught = false;
	try
	{
		parse(" test)");
	}
	catch(Exception ex)
	{
		caught = true;
	}
	assert(caught);
}

}