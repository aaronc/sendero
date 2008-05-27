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

#line 175 "sendero/view/expression/Compile.rl"



#line 31 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 9, 1, 
	11, 1, 12, 2, 0, 9, 2, 1, 
	8, 2, 2, 10, 2, 6, 5, 2, 
	7, 9, 2, 9, 11, 2, 9, 12, 
	2, 11, 12, 3, 0, 2, 10, 3, 
	1, 8, 12, 3, 2, 10, 12, 3, 
	4, 2, 10, 3, 5, 2, 10, 3, 
	6, 1, 8, 3, 6, 2, 10, 3, 
	7, 1, 8, 3, 7, 2, 10, 3, 
	9, 2, 10, 3, 9, 11, 12, 4, 
	1, 8, 2, 10, 4, 1, 8, 11, 
	12, 4, 2, 10, 11, 12, 4, 9, 
	2, 10, 12, 5, 1, 8, 2, 10, 
	12, 5, 9, 2, 10, 11, 12, 6, 
	1, 8, 2, 10, 11, 12
];

static const short[] _sendero_view_compile_key_offsets = [
	0, 0, 23, 24, 26, 29, 33, 56, 
	59, 82, 83, 85, 88, 111, 134, 139, 
	144, 167, 177, 182, 199, 222, 226, 231, 
	240, 245, 262, 285, 289, 296, 300, 318, 
	341, 343, 343, 367, 390, 393, 395, 402, 
	405, 428, 432, 455, 460, 470, 486, 501, 
	521, 531, 538, 561, 566, 583, 603, 608, 
	627, 635, 640, 663, 669, 685, 705, 711, 
	719, 725, 741, 761, 771, 778
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
	33u, 37u, 40u, 41u, 47u, 60u, 61u, 62u, 
	92u, 93u, 95u, 9u, 13u, 32u, 34u, 39u, 
	45u, 48u, 57u, 65u, 90u, 97u, 122u, 33u, 
	37u, 40u, 41u, 47u, 60u, 61u, 62u, 92u, 
	93u, 96u, 9u, 13u, 32u, 34u, 39u, 45u, 
	48u, 57u, 65u, 90u, 95u, 122u, 34u, 39u, 
	61u, 92u, 96u, 34u, 46u, 92u, 48u, 57u, 
	33u, 37u, 40u, 41u, 47u, 62u, 92u, 93u, 
	96u, 9u, 13u, 32u, 34u, 39u, 45u, 48u, 
	57u, 60u, 61u, 65u, 90u, 95u, 122u, 34u, 
	39u, 92u, 96u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 40u, 46u, 91u, 92u, 33u, 34u, 
	40u, 41u, 46u, 91u, 92u, 93u, 95u, 48u, 
	57u, 60u, 61u, 65u, 90u, 97u, 122u, 32u, 
	33u, 34u, 37u, 40u, 41u, 47u, 62u, 92u, 
	93u, 96u, 9u, 13u, 39u, 45u, 48u, 57u, 
	60u, 61u, 65u, 90u, 95u, 122u, 39u, 61u, 
	92u, 96u, 39u, 46u, 92u, 48u, 57u, 39u, 
	92u, 96u, 48u, 57u, 65u, 90u, 95u, 122u, 
	39u, 40u, 46u, 91u, 92u, 33u, 34u, 39u, 
	40u, 41u, 46u, 91u, 93u, 95u, 48u, 57u, 
	60u, 61u, 65u, 90u, 97u, 122u, 32u, 33u, 
	34u, 37u, 39u, 40u, 41u, 47u, 62u, 93u, 
	96u, 9u, 13u, 42u, 45u, 48u, 57u, 60u, 
	61u, 65u, 90u, 95u, 122u, 46u, 96u, 48u, 
	57u, 96u, 48u, 57u, 65u, 90u, 95u, 122u, 
	40u, 46u, 91u, 96u, 33u, 34u, 39u, 40u, 
	41u, 46u, 47u, 91u, 93u, 96u, 48u, 57u, 
	60u, 61u, 65u, 90u, 95u, 122u, 32u, 33u, 
	34u, 37u, 39u, 40u, 41u, 47u, 62u, 93u, 
	96u, 9u, 13u, 42u, 45u, 48u, 57u, 60u, 
	61u, 65u, 90u, 95u, 122u, 39u, 92u, 32u, 
	33u, 34u, 37u, 39u, 40u, 41u, 42u, 47u, 
	60u, 61u, 62u, 93u, 96u, 9u, 13u, 43u, 
	45u, 48u, 57u, 65u, 90u, 95u, 122u, 32u, 
	33u, 34u, 37u, 39u, 40u, 41u, 47u, 60u, 
	61u, 62u, 93u, 96u, 9u, 13u, 42u, 45u, 
	48u, 57u, 65u, 90u, 95u, 122u, 46u, 48u, 
	57u, 61u, 62u, 95u, 48u, 57u, 65u, 90u, 
	97u, 122u, 40u, 46u, 91u, 33u, 37u, 40u, 
	41u, 47u, 60u, 61u, 62u, 92u, 93u, 96u, 
	9u, 13u, 32u, 34u, 42u, 45u, 48u, 57u, 
	65u, 90u, 95u, 122u, 34u, 39u, 61u, 92u, 
	33u, 37u, 40u, 41u, 47u, 62u, 92u, 93u, 
	95u, 9u, 13u, 32u, 34u, 39u, 45u, 48u, 
	57u, 60u, 61u, 65u, 90u, 97u, 122u, 34u, 
	39u, 92u, 61u, 62u, 34u, 39u, 92u, 95u, 
	48u, 57u, 65u, 90u, 97u, 122u, 33u, 40u, 
	41u, 46u, 91u, 92u, 93u, 95u, 48u, 57u, 
	60u, 61u, 65u, 90u, 97u, 122u, 33u, 40u, 
	41u, 46u, 92u, 93u, 95u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	40u, 41u, 47u, 60u, 62u, 92u, 96u, 9u, 
	13u, 39u, 45u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 46u, 92u, 95u, 48u, 57u, 65u, 
	90u, 97u, 122u, 34u, 40u, 46u, 91u, 92u, 
	48u, 57u, 32u, 33u, 34u, 37u, 40u, 41u, 
	47u, 60u, 61u, 62u, 92u, 93u, 95u, 9u, 
	13u, 39u, 45u, 48u, 57u, 65u, 90u, 97u, 
	122u, 39u, 92u, 96u, 61u, 62u, 33u, 34u, 
	39u, 40u, 41u, 46u, 47u, 93u, 96u, 48u, 
	57u, 60u, 61u, 65u, 90u, 95u, 122u, 32u, 
	34u, 37u, 39u, 40u, 41u, 47u, 60u, 62u, 
	96u, 9u, 13u, 42u, 45u, 48u, 57u, 65u, 
	90u, 95u, 122u, 34u, 40u, 46u, 91u, 92u, 
	33u, 34u, 39u, 40u, 41u, 42u, 46u, 47u, 
	91u, 93u, 96u, 48u, 57u, 60u, 61u, 65u, 
	90u, 95u, 122u, 46u, 95u, 48u, 57u, 65u, 
	90u, 97u, 122u, 40u, 46u, 91u, 48u, 57u, 
	33u, 37u, 40u, 41u, 47u, 60u, 61u, 62u, 
	92u, 93u, 96u, 9u, 13u, 32u, 34u, 42u, 
	45u, 48u, 57u, 65u, 90u, 95u, 122u, 34u, 
	39u, 92u, 96u, 61u, 62u, 33u, 34u, 39u, 
	40u, 41u, 46u, 93u, 95u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	39u, 40u, 41u, 47u, 60u, 62u, 96u, 9u, 
	13u, 42u, 45u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 40u, 46u, 91u, 92u, 96u, 46u, 
	96u, 48u, 57u, 65u, 90u, 95u, 122u, 40u, 
	46u, 91u, 96u, 48u, 57u, 33u, 34u, 40u, 
	41u, 46u, 92u, 93u, 95u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	40u, 41u, 47u, 60u, 62u, 92u, 96u, 9u, 
	13u, 39u, 45u, 48u, 57u, 65u, 90u, 95u, 
	122u, 39u, 46u, 92u, 95u, 48u, 57u, 65u, 
	90u, 97u, 122u, 39u, 40u, 46u, 91u, 92u, 
	48u, 57u, 96u, 61u, 62u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 13, 1, 2, 3, 4, 13, 3, 
	13, 1, 2, 3, 11, 11, 5, 3, 
	9, 4, 5, 9, 11, 4, 3, 3, 
	5, 9, 11, 2, 1, 4, 10, 11, 
	2, 0, 14, 13, 1, 0, 1, 3, 
	11, 4, 9, 3, 4, 8, 7, 10, 
	4, 5, 13, 3, 9, 10, 5, 11, 
	2, 3, 11, 4, 8, 10, 6, 2, 
	4, 8, 10, 4, 5, 1
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 5, 0, 0, 0, 0, 5, 0, 
	5, 0, 0, 0, 6, 6, 0, 1, 
	7, 3, 0, 4, 6, 0, 1, 3, 
	0, 4, 6, 1, 3, 0, 4, 6, 
	0, 0, 5, 5, 1, 1, 3, 0, 
	6, 0, 7, 1, 3, 4, 4, 5, 
	3, 1, 5, 1, 4, 5, 0, 4, 
	3, 1, 6, 1, 4, 5, 0, 3, 
	1, 4, 5, 3, 1, 1
];

static const short[] _sendero_view_compile_index_offsets = [
	0, 0, 19, 21, 24, 28, 33, 52, 
	56, 75, 77, 80, 84, 102, 120, 126, 
	131, 148, 156, 162, 176, 194, 199, 204, 
	211, 217, 231, 249, 253, 258, 263, 278, 
	296, 299, 300, 320, 339, 342, 344, 349, 
	353, 371, 376, 393, 398, 406, 419, 431, 
	447, 455, 462, 481, 486, 500, 516, 522, 
	538, 544, 549, 567, 573, 586, 602, 609, 
	615, 621, 634, 650, 658, 665
];

static const ubyte[] _sendero_view_compile_indicies = [
	0, 2, 3, 0, 4, 5, 6, 7, 
	9, 10, 0, 12, 13, 0, 0, 8, 
	11, 11, 1, 0, 1, 15, 16, 14, 
	18, 19, 20, 17, 18, 19, 20, 19, 
	17, 18, 22, 17, 18, 23, 24, 18, 
	26, 27, 18, 29, 30, 18, 18, 18, 
	25, 28, 28, 21, 31, 29, 18, 21, 
	31, 32, 33, 31, 21, 34, 35, 31, 
	37, 38, 31, 40, 31, 31, 31, 36, 
	39, 39, 13, 0, 13, 31, 0, 13, 
	18, 41, 42, 17, 43, 19, 44, 45, 
	19, 47, 48, 19, 20, 50, 49, 19, 
	19, 19, 46, 49, 49, 17, 43, 19, 
	44, 45, 19, 47, 48, 19, 20, 50, 
	19, 19, 19, 19, 46, 49, 49, 17, 
	18, 19, 19, 20, 19, 17, 52, 53, 
	54, 53, 51, 43, 19, 44, 45, 19, 
	19, 20, 50, 19, 19, 19, 19, 46, 
	47, 49, 49, 17, 56, 57, 59, 57, 
	58, 58, 58, 55, 61, 62, 63, 64, 
	65, 60, 66, 60, 67, 68, 69, 72, 
	73, 74, 71, 70, 66, 71, 71, 61, 
	18, 22, 17, 18, 23, 24, 18, 18, 
	29, 30, 18, 18, 18, 25, 26, 28, 
	28, 21, 31, 18, 29, 18, 21, 75, 
	76, 77, 76, 52, 79, 81, 56, 80, 
	80, 80, 78, 82, 83, 69, 72, 73, 
	61, 84, 85, 61, 86, 87, 88, 91, 
	92, 90, 89, 84, 90, 90, 82, 31, 
	32, 33, 31, 21, 34, 35, 31, 31, 
	40, 31, 31, 31, 36, 37, 39, 39, 
	13, 93, 94, 93, 75, 97, 96, 96, 
	96, 95, 98, 88, 91, 99, 82, 100, 
	101, 102, 103, 104, 105, 106, 109, 110, 
	82, 107, 100, 108, 108, 99, 0, 2, 
	3, 0, 4, 5, 6, 7, 0, 12, 
	13, 0, 0, 8, 9, 11, 11, 1, 
	31, 29, 21, 1, 0, 2, 3, 0, 
	4, 5, 6, 111, 7, 9, 10, 0, 
	12, 13, 0, 0, 8, 11, 11, 1, 
	0, 2, 3, 0, 4, 5, 6, 7, 
	9, 10, 0, 12, 13, 0, 0, 8, 
	11, 11, 112, 113, 113, 94, 0, 1, 
	115, 115, 115, 115, 114, 116, 105, 109, 
	99, 117, 42, 118, 119, 42, 120, 121, 
	42, 16, 50, 17, 42, 42, 42, 46, 
	122, 122, 14, 18, 19, 19, 20, 17, 
	43, 19, 44, 45, 19, 19, 20, 50, 
	49, 19, 19, 19, 46, 47, 49, 49, 
	17, 18, 19, 20, 19, 17, 56, 57, 
	59, 58, 58, 58, 58, 55, 123, 124, 
	125, 63, 64, 65, 128, 127, 126, 123, 
	127, 127, 60, 129, 130, 131, 53, 54, 
	133, 132, 46, 129, 132, 132, 51, 57, 
	57, 57, 134, 135, 57, 57, 57, 59, 
	57, 57, 57, 136, 49, 49, 55, 138, 
	139, 142, 141, 140, 141, 141, 137, 144, 
	145, 146, 148, 149, 147, 143, 18, 22, 
	17, 18, 23, 24, 18, 26, 27, 18, 
	29, 30, 28, 18, 18, 25, 28, 28, 
	21, 31, 29, 18, 18, 21, 150, 151, 
	152, 153, 154, 113, 155, 157, 75, 8, 
	150, 156, 156, 94, 97, 158, 97, 78, 
	159, 160, 161, 97, 97, 95, 97, 97, 
	162, 11, 11, 114, 102, 164, 165, 166, 
	167, 163, 100, 101, 102, 103, 104, 168, 
	105, 106, 109, 110, 82, 107, 100, 108, 
	108, 99, 170, 172, 171, 172, 172, 169, 
	174, 175, 177, 176, 173, 43, 19, 44, 
	45, 19, 47, 48, 19, 41, 50, 19, 
	19, 19, 19, 46, 49, 49, 17, 18, 
	19, 20, 19, 19, 17, 178, 179, 52, 
	180, 181, 93, 183, 182, 36, 178, 182, 
	182, 75, 79, 184, 79, 78, 185, 186, 
	79, 79, 79, 79, 79, 79, 187, 39, 
	39, 95, 61, 62, 63, 64, 188, 163, 
	60, 190, 169, 191, 192, 192, 189, 194, 
	195, 197, 173, 196, 193, 198, 51, 199, 
	200, 76, 77, 202, 201, 25, 198, 201, 
	201, 52, 56, 55, 56, 203, 204, 56, 
	56, 56, 81, 56, 56, 56, 205, 28, 
	28, 78, 189, 206, 209, 208, 207, 208, 
	208, 138, 193, 210, 211, 213, 214, 212, 
	144, 0, 31, 13, 0
];

static const byte[] _sendero_view_compile_trans_targs = [
	1, 0, 2, 3, 32, 1, 33, 34, 
	36, 31, 37, 38, 39, 9, 4, 50, 
	4, 5, 6, 13, 5, 7, 21, 6, 
	7, 22, 20, 51, 23, 7, 24, 8, 
	10, 11, 8, 9, 27, 26, 69, 28, 
	29, 5, 12, 14, 13, 5, 15, 16, 
	59, 17, 18, 13, 6, 15, 13, 18, 
	19, 45, 17, 18, 13, 6, 13, 13, 
	13, 13, 20, 6, 6, 6, 65, 66, 
	6, 6, 19, 8, 22, 6, 24, 25, 
	23, 24, 8, 6, 26, 58, 8, 8, 
	8, 60, 61, 8, 25, 27, 1, 29, 
	28, 30, 8, 1, 31, 40, 50, 1, 
	1, 1, 34, 52, 53, 1, 30, 35, 
	33, 36, 39, 38, 1, 41, 12, 4, 
	42, 43, 44, 16, 13, 13, 46, 47, 
	45, 16, 13, 13, 47, 45, 45, 18, 
	48, 45, 19, 49, 48, 47, 45, 13, 
	6, 13, 46, 46, 13, 13, 31, 40, 
	50, 1, 1, 34, 53, 30, 54, 30, 
	39, 55, 56, 12, 12, 12, 12, 12, 
	35, 30, 57, 56, 53, 1, 1, 52, 
	52, 1, 26, 58, 8, 8, 61, 25, 
	62, 25, 29, 63, 13, 25, 64, 63, 
	61, 8, 8, 60, 60, 8, 20, 6, 
	6, 66, 19, 19, 24, 67, 68, 67, 
	66, 19, 6, 65, 65, 6, 6
];

static const byte[] _sendero_view_compile_trans_actions = [
	0, 0, 0, 0, 0, 9, 11, 0, 
	1, 0, 0, 1, 0, 0, 0, 0, 
	15, 0, 0, 0, 40, 0, 0, 9, 
	11, 1, 0, 0, 1, 17, 0, 0, 
	0, 0, 9, 11, 1, 0, 0, 1, 
	0, 15, 0, 0, 9, 11, 1, 0, 
	0, 1, 0, 25, 25, 0, 97, 22, 
	22, 22, 0, 92, 13, 13, 7, 3, 
	5, 83, 13, 28, 31, 3, 19, 19, 
	5, 37, 13, 25, 0, 51, 22, 22, 
	0, 47, 13, 7, 13, 13, 28, 31, 
	3, 19, 19, 5, 13, 0, 25, 22, 
	0, 22, 7, 13, 13, 13, 13, 28, 
	31, 3, 13, 19, 19, 5, 13, 0, 
	0, 0, 22, 0, 7, 0, 9, 11, 
	0, 0, 1, 13, 28, 31, 19, 19, 
	13, 25, 67, 75, 43, 25, 63, 71, 
	1, 87, 87, 22, 0, 25, 119, 79, 
	79, 59, 3, 13, 55, 113, 25, 25, 
	25, 67, 75, 25, 43, 25, 22, 63, 
	71, 22, 1, 13, 7, 3, 5, 34, 
	13, 87, 22, 0, 25, 79, 59, 3, 
	13, 55, 25, 25, 67, 75, 43, 25, 
	22, 63, 71, 1, 34, 87, 22, 0, 
	25, 79, 59, 3, 13, 55, 25, 67, 
	75, 43, 25, 63, 71, 1, 22, 0, 
	25, 107, 59, 3, 13, 55, 102
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 70;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;
static const int sendero_view_compile_en_main_Expression_end_call = 39;

#line 178 "sendero/view/expression/Compile.rl"


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
	
#line 392 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 217 "sendero/view/expression/Compile.rl"
	
#line 396 "sendero/view/expression/Compile.d"
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
#line 128 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 9:
#line 138 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 10:
#line 143 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 11:
#line 148 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 12:
#line 155 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
#line 548 "sendero/view/expression/Compile.d"
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
#line 218 "sendero/view/expression/Compile.rl"
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

/+

+ -
* /

5 + 7 * 3 / 7 + 1

lhs mhs rhs
if(lhs) {
	if(lhs.op.precedence < cur.precendence) {
		*pRhs = curAtom;
		lhs = new BinaryExpression(cur)(lhs, null);
		pRhs = &lhs.rhs;
	}
	else {
		if(pRhs.op.precendence < cur.precedence) {
			*pRhs = new BinaryExpression(curAtom, null);
		}
		else {
			pRhs = &lhs.rhs.rhs;
		}
	}
}
else {
	lhs = new BinaryExpression(curAtom, null);
	pRhs = &lhs.rhs;
}


+/