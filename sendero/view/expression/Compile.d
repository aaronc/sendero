#line 1 "sendero/view/expression/Compile.rl"
module sendero.view.expression.Compile;

import sendero_base.Core;
import sendero.vm.Expression2;

import sendero_base.util.collection.Stack;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

debug import tango.io.Stdout;

void error(char[] msg)
{
	throw new Exception(msg);
}

#line 167 "sendero/view/expression/Compile.rl"



#line 21 "sendero/view/expression/Compile.d"
static const byte[] _sendero_view_compile_actions = [
	0, 1, 0, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 15, 1, 17, 1, 18, 2, 
	0, 15, 2, 1, 14, 2, 2, 16, 
	2, 6, 5, 2, 7, 15, 2, 8, 
	15, 2, 9, 15, 2, 10, 15, 2, 
	11, 15, 2, 12, 15, 2, 13, 15, 
	2, 15, 17, 2, 15, 18, 2, 17, 
	18, 3, 0, 2, 16, 3, 1, 14, 
	18, 3, 2, 16, 18, 3, 4, 2, 
	16, 3, 5, 2, 16, 3, 6, 1, 
	14, 3, 6, 2, 16, 3, 7, 1, 
	14, 3, 7, 2, 16, 3, 8, 1, 
	14, 3, 8, 2, 16, 3, 9, 1, 
	14, 3, 9, 2, 16, 3, 10, 1, 
	14, 3, 10, 2, 16, 3, 11, 1, 
	14, 3, 11, 2, 16, 3, 12, 1, 
	14, 3, 12, 2, 16, 3, 13, 1, 
	14, 3, 13, 2, 16, 3, 15, 2, 
	16, 3, 15, 17, 18, 4, 1, 14, 
	2, 16, 4, 1, 14, 17, 18, 4, 
	2, 16, 17, 18, 4, 15, 2, 16, 
	18, 5, 1, 14, 2, 16, 18, 5, 
	15, 2, 16, 17, 18, 6, 1, 14, 
	2, 16, 17, 18
];

static const short[] _sendero_view_compile_key_offsets = [
	0, 0, 27, 28, 30, 33, 37, 65, 
	68, 95, 96, 98, 101, 129, 157, 162, 
	167, 172, 200, 210, 215, 240, 268, 272, 
	276, 281, 290, 295, 320, 347, 349, 353, 
	360, 364, 389, 416, 417, 419, 419, 446, 
	473, 476, 478, 485, 488, 489, 516, 520, 
	524, 552, 557, 562, 572, 596, 624, 630, 
	653, 676, 686, 693, 721, 725, 752, 780, 
	785, 789, 813, 835, 840, 865, 892, 900, 
	905, 907, 934, 961, 964, 988, 1010, 1016, 
	1024, 1030, 1057, 1085, 1109, 1132, 1142, 1149
];

static const char[] _sendero_view_compile_trans_keys = [
	32u, 33u, 34u, 37u, 38u, 39u, 40u, 41u, 
	42u, 43u, 44u, 45u, 47u, 60u, 61u, 62u, 
	93u, 96u, 124u, 9u, 13u, 48u, 57u, 65u, 
	90u, 95u, 122u, 61u, 34u, 92u, 34u, 39u, 
	92u, 34u, 39u, 92u, 96u, 32u, 33u, 34u, 
	37u, 38u, 39u, 40u, 41u, 42u, 43u, 44u, 
	45u, 47u, 60u, 61u, 62u, 92u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 65u, 90u, 95u, 
	122u, 39u, 92u, 96u, 32u, 33u, 34u, 37u, 
	38u, 39u, 40u, 41u, 42u, 43u, 44u, 45u, 
	47u, 60u, 61u, 62u, 93u, 96u, 124u, 9u, 
	13u, 48u, 57u, 65u, 90u, 95u, 122u, 96u, 
	61u, 96u, 34u, 92u, 96u, 33u, 37u, 38u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 61u, 62u, 92u, 93u, 95u, 124u, 9u, 
	13u, 32u, 34u, 48u, 57u, 65u, 90u, 97u, 
	122u, 33u, 37u, 38u, 39u, 40u, 41u, 42u, 
	43u, 44u, 45u, 47u, 60u, 61u, 62u, 92u, 
	93u, 96u, 124u, 9u, 13u, 32u, 34u, 48u, 
	57u, 65u, 90u, 95u, 122u, 34u, 39u, 61u, 
	92u, 96u, 34u, 92u, 96u, 38u, 39u, 34u, 
	46u, 92u, 48u, 57u, 33u, 37u, 38u, 39u, 
	40u, 41u, 42u, 43u, 44u, 45u, 47u, 62u, 
	92u, 93u, 96u, 124u, 9u, 13u, 32u, 34u, 
	48u, 57u, 60u, 61u, 65u, 90u, 95u, 122u, 
	34u, 39u, 92u, 96u, 48u, 57u, 65u, 90u, 
	95u, 122u, 34u, 40u, 46u, 91u, 92u, 33u, 
	34u, 37u, 38u, 40u, 41u, 42u, 43u, 44u, 
	45u, 46u, 47u, 91u, 92u, 93u, 95u, 124u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	32u, 33u, 34u, 37u, 38u, 39u, 40u, 41u, 
	42u, 43u, 44u, 45u, 47u, 62u, 92u, 93u, 
	96u, 124u, 9u, 13u, 48u, 57u, 60u, 61u, 
	65u, 90u, 95u, 122u, 39u, 61u, 92u, 96u, 
	38u, 39u, 92u, 96u, 39u, 46u, 92u, 48u, 
	57u, 39u, 92u, 96u, 48u, 57u, 65u, 90u, 
	95u, 122u, 39u, 40u, 46u, 91u, 92u, 33u, 
	34u, 37u, 38u, 39u, 40u, 41u, 42u, 43u, 
	44u, 45u, 46u, 47u, 91u, 93u, 95u, 124u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	32u, 33u, 34u, 37u, 38u, 39u, 40u, 41u, 
	42u, 43u, 44u, 45u, 47u, 62u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 60u, 61u, 65u, 
	90u, 95u, 122u, 38u, 96u, 46u, 96u, 48u, 
	57u, 96u, 48u, 57u, 65u, 90u, 95u, 122u, 
	40u, 46u, 91u, 96u, 33u, 34u, 37u, 38u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 46u, 
	47u, 91u, 93u, 96u, 124u, 48u, 57u, 60u, 
	61u, 65u, 90u, 95u, 122u, 32u, 33u, 34u, 
	37u, 38u, 39u, 40u, 41u, 42u, 43u, 44u, 
	45u, 47u, 62u, 93u, 96u, 124u, 9u, 13u, 
	48u, 57u, 60u, 61u, 65u, 90u, 95u, 122u, 
	38u, 39u, 92u, 32u, 33u, 34u, 37u, 38u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 61u, 62u, 93u, 96u, 124u, 9u, 13u, 
	48u, 57u, 65u, 90u, 95u, 122u, 32u, 33u, 
	34u, 37u, 38u, 39u, 40u, 41u, 42u, 43u, 
	44u, 45u, 47u, 60u, 61u, 62u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 65u, 90u, 95u, 
	122u, 46u, 48u, 57u, 61u, 62u, 95u, 48u, 
	57u, 65u, 90u, 97u, 122u, 40u, 46u, 91u, 
	124u, 33u, 37u, 38u, 40u, 41u, 42u, 43u, 
	44u, 45u, 47u, 60u, 61u, 62u, 92u, 93u, 
	96u, 124u, 9u, 13u, 32u, 34u, 48u, 57u, 
	65u, 90u, 95u, 122u, 34u, 39u, 61u, 92u, 
	34u, 92u, 38u, 39u, 33u, 37u, 38u, 39u, 
	40u, 41u, 42u, 43u, 44u, 45u, 47u, 62u, 
	92u, 93u, 95u, 124u, 9u, 13u, 32u, 34u, 
	48u, 57u, 60u, 61u, 65u, 90u, 97u, 122u, 
	34u, 39u, 92u, 96u, 124u, 34u, 39u, 92u, 
	61u, 62u, 34u, 39u, 92u, 95u, 48u, 57u, 
	65u, 90u, 97u, 122u, 33u, 37u, 38u, 40u, 
	41u, 42u, 43u, 44u, 45u, 46u, 47u, 91u, 
	92u, 93u, 95u, 124u, 48u, 57u, 60u, 61u, 
	65u, 90u, 97u, 122u, 33u, 37u, 38u, 39u, 
	40u, 41u, 42u, 43u, 44u, 45u, 47u, 60u, 
	61u, 62u, 92u, 93u, 96u, 124u, 9u, 13u, 
	32u, 34u, 48u, 57u, 65u, 90u, 95u, 122u, 
	34u, 39u, 92u, 96u, 61u, 62u, 33u, 37u, 
	38u, 40u, 41u, 42u, 43u, 44u, 45u, 46u, 
	47u, 92u, 93u, 95u, 124u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 62u, 92u, 96u, 9u, 13u, 48u, 57u, 
	65u, 90u, 95u, 122u, 34u, 46u, 92u, 95u, 
	48u, 57u, 65u, 90u, 97u, 122u, 34u, 40u, 
	46u, 91u, 92u, 48u, 57u, 33u, 37u, 38u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 61u, 62u, 92u, 93u, 96u, 124u, 9u, 
	13u, 32u, 34u, 48u, 57u, 65u, 90u, 95u, 
	122u, 34u, 39u, 92u, 124u, 32u, 33u, 34u, 
	37u, 38u, 39u, 40u, 41u, 42u, 43u, 44u, 
	45u, 47u, 60u, 61u, 62u, 93u, 96u, 124u, 
	9u, 13u, 48u, 57u, 65u, 90u, 95u, 122u, 
	32u, 33u, 34u, 37u, 38u, 39u, 40u, 41u, 
	42u, 43u, 44u, 45u, 47u, 60u, 61u, 62u, 
	92u, 93u, 95u, 124u, 9u, 13u, 48u, 57u, 
	65u, 90u, 97u, 122u, 39u, 92u, 96u, 61u, 
	62u, 39u, 92u, 96u, 124u, 33u, 34u, 37u, 
	38u, 39u, 40u, 41u, 42u, 43u, 44u, 45u, 
	46u, 47u, 93u, 96u, 124u, 48u, 57u, 60u, 
	61u, 65u, 90u, 95u, 122u, 32u, 34u, 37u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 62u, 96u, 9u, 13u, 48u, 57u, 65u, 
	90u, 95u, 122u, 34u, 40u, 46u, 91u, 92u, 
	33u, 34u, 37u, 38u, 39u, 40u, 41u, 42u, 
	43u, 44u, 45u, 46u, 47u, 91u, 93u, 96u, 
	124u, 48u, 57u, 60u, 61u, 65u, 90u, 95u, 
	122u, 32u, 33u, 34u, 37u, 38u, 39u, 40u, 
	41u, 42u, 43u, 44u, 45u, 47u, 60u, 61u, 
	62u, 93u, 96u, 124u, 9u, 13u, 48u, 57u, 
	65u, 90u, 95u, 122u, 46u, 95u, 48u, 57u, 
	65u, 90u, 97u, 122u, 40u, 46u, 91u, 48u, 
	57u, 96u, 124u, 33u, 37u, 38u, 40u, 41u, 
	42u, 43u, 44u, 45u, 47u, 60u, 61u, 62u, 
	92u, 93u, 96u, 124u, 9u, 13u, 32u, 34u, 
	48u, 57u, 65u, 90u, 95u, 122u, 32u, 33u, 
	34u, 37u, 38u, 39u, 40u, 41u, 42u, 43u, 
	44u, 45u, 47u, 60u, 61u, 62u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 65u, 90u, 95u, 
	122u, 96u, 61u, 62u, 33u, 34u, 37u, 38u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 46u, 
	47u, 93u, 95u, 124u, 48u, 57u, 60u, 61u, 
	65u, 90u, 97u, 122u, 32u, 34u, 37u, 39u, 
	40u, 41u, 42u, 43u, 44u, 45u, 47u, 60u, 
	62u, 96u, 9u, 13u, 48u, 57u, 65u, 90u, 
	95u, 122u, 34u, 40u, 46u, 91u, 92u, 96u, 
	46u, 96u, 48u, 57u, 65u, 90u, 95u, 122u, 
	40u, 46u, 91u, 96u, 48u, 57u, 32u, 33u, 
	34u, 37u, 38u, 39u, 40u, 41u, 42u, 43u, 
	44u, 45u, 47u, 60u, 61u, 62u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 65u, 90u, 95u, 
	122u, 32u, 33u, 34u, 37u, 38u, 39u, 40u, 
	41u, 42u, 43u, 44u, 45u, 47u, 60u, 61u, 
	62u, 92u, 93u, 96u, 124u, 9u, 13u, 48u, 
	57u, 65u, 90u, 95u, 122u, 33u, 34u, 37u, 
	38u, 40u, 41u, 42u, 43u, 44u, 45u, 46u, 
	47u, 92u, 93u, 95u, 124u, 48u, 57u, 60u, 
	61u, 65u, 90u, 97u, 122u, 32u, 34u, 37u, 
	39u, 40u, 41u, 42u, 43u, 44u, 45u, 47u, 
	60u, 62u, 92u, 96u, 9u, 13u, 48u, 57u, 
	65u, 90u, 95u, 122u, 39u, 46u, 92u, 95u, 
	48u, 57u, 65u, 90u, 97u, 122u, 39u, 40u, 
	46u, 91u, 92u, 48u, 57u, 32u, 33u, 34u, 
	37u, 38u, 39u, 40u, 41u, 42u, 43u, 44u, 
	45u, 47u, 60u, 61u, 62u, 92u, 93u, 96u, 
	124u, 9u, 13u, 48u, 57u, 65u, 90u, 95u, 
	122u, 0
];

static const byte[] _sendero_view_compile_single_lengths = [
	0, 19, 1, 2, 3, 4, 20, 3, 
	19, 1, 2, 3, 18, 18, 5, 3, 
	3, 16, 4, 5, 17, 18, 4, 4, 
	3, 3, 5, 17, 17, 2, 2, 1, 
	4, 17, 17, 1, 2, 0, 19, 19, 
	1, 0, 1, 3, 1, 17, 4, 2, 
	16, 5, 3, 4, 16, 18, 4, 15, 
	15, 4, 5, 18, 4, 19, 20, 3, 
	4, 16, 14, 5, 17, 19, 2, 3, 
	2, 17, 19, 1, 16, 14, 6, 2, 
	4, 19, 20, 16, 15, 4, 5, 20
];

static const byte[] _sendero_view_compile_range_lengths = [
	0, 4, 0, 0, 0, 0, 4, 0, 
	4, 0, 0, 0, 5, 5, 0, 1, 
	1, 6, 3, 0, 4, 5, 0, 0, 
	1, 3, 0, 4, 5, 0, 1, 3, 
	0, 4, 5, 0, 0, 0, 4, 4, 
	1, 1, 3, 0, 0, 5, 0, 1, 
	6, 0, 1, 3, 4, 5, 1, 4, 
	4, 3, 1, 5, 0, 4, 4, 1, 
	0, 4, 4, 0, 4, 4, 3, 1, 
	0, 5, 4, 1, 4, 4, 0, 3, 
	1, 4, 4, 4, 4, 3, 1, 4
];

static const short[] _sendero_view_compile_index_offsets = [
	0, 0, 24, 26, 29, 33, 38, 63, 
	67, 91, 93, 96, 100, 124, 148, 154, 
	159, 164, 187, 195, 201, 223, 247, 252, 
	257, 262, 269, 275, 297, 320, 323, 327, 
	332, 337, 359, 382, 384, 387, 388, 412, 
	436, 439, 441, 446, 450, 452, 475, 480, 
	484, 507, 513, 518, 526, 547, 571, 577, 
	597, 617, 625, 632, 656, 661, 685, 710, 
	715, 720, 741, 760, 766, 788, 812, 818, 
	823, 826, 849, 873, 876, 897, 916, 923, 
	929, 935, 959, 984, 1005, 1025, 1033, 1040
];

static const byte[] _sendero_view_compile_trans_targs = [
	1, 2, 3, 1, 35, 36, 1, 37, 
	1, 1, 1, 1, 38, 34, 41, 1, 
	43, 9, 44, 1, 40, 42, 42, 0, 
	1, 0, 62, 4, 4, 6, 13, 5, 
	5, 6, 13, 5, 13, 5, 6, 22, 
	5, 6, 23, 6, 6, 7, 6, 6, 
	6, 6, 6, 21, 63, 6, 7, 26, 
	6, 64, 6, 24, 25, 25, 7, 8, 
	7, 6, 7, 8, 10, 11, 8, 29, 
	7, 8, 9, 8, 8, 8, 8, 8, 
	28, 75, 8, 32, 8, 72, 8, 30, 
	31, 31, 9, 1, 9, 8, 1, 9, 
	6, 5, 12, 5, 14, 13, 15, 13, 
	13, 5, 13, 13, 13, 13, 13, 17, 
	54, 13, 5, 19, 18, 49, 13, 13, 
	16, 18, 18, 5, 14, 13, 15, 13, 
	13, 5, 13, 13, 13, 13, 13, 17, 
	54, 13, 5, 19, 13, 49, 13, 13, 
	16, 18, 18, 5, 6, 13, 13, 5, 
	13, 5, 6, 5, 13, 13, 5, 6, 
	16, 13, 16, 13, 14, 13, 15, 13, 
	13, 5, 13, 13, 13, 13, 13, 13, 
	5, 19, 13, 49, 13, 13, 16, 17, 
	18, 18, 5, 20, 52, 19, 52, 18, 
	18, 18, 19, 6, 13, 13, 13, 13, 
	13, 21, 13, 6, 82, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 20, 
	84, 87, 83, 21, 84, 84, 6, 6, 
	22, 5, 6, 23, 6, 6, 7, 6, 
	6, 6, 6, 6, 6, 7, 26, 6, 
	64, 6, 24, 21, 25, 25, 7, 8, 
	6, 7, 6, 7, 6, 8, 7, 6, 
	7, 8, 24, 6, 24, 6, 27, 26, 
	20, 25, 25, 25, 26, 8, 6, 6, 
	6, 6, 6, 28, 73, 8, 74, 6, 
	8, 8, 8, 8, 8, 8, 8, 8, 
	8, 27, 77, 81, 76, 28, 77, 77, 
	8, 8, 10, 11, 8, 29, 7, 8, 
	9, 8, 8, 8, 8, 8, 8, 32, 
	8, 72, 8, 30, 28, 31, 31, 9, 
	8, 1, 9, 30, 1, 30, 8, 33, 
	31, 31, 31, 32, 8, 8, 8, 1, 
	8, 34, 45, 1, 61, 62, 1, 1, 
	1, 1, 1, 1, 1, 38, 1, 33, 
	8, 69, 65, 34, 66, 66, 1, 1, 
	2, 3, 1, 35, 36, 1, 37, 1, 
	1, 1, 1, 38, 1, 43, 9, 44, 
	1, 40, 34, 42, 42, 0, 1, 0, 
	8, 7, 7, 0, 1, 2, 3, 1, 
	35, 36, 1, 37, 39, 1, 1, 1, 
	38, 34, 41, 1, 43, 9, 44, 1, 
	40, 42, 42, 0, 1, 2, 3, 1, 
	35, 36, 1, 37, 1, 1, 1, 1, 
	38, 34, 41, 1, 43, 9, 44, 1, 
	40, 42, 42, 37, 40, 40, 1, 1, 
	0, 42, 42, 42, 42, 43, 1, 1, 
	1, 1, 1, 0, 46, 12, 47, 12, 
	4, 12, 12, 12, 12, 12, 48, 50, 
	12, 4, 19, 5, 60, 12, 12, 16, 
	51, 51, 4, 6, 13, 13, 5, 5, 
	6, 5, 13, 5, 14, 13, 15, 13, 
	13, 5, 13, 13, 13, 13, 13, 13, 
	5, 19, 18, 49, 13, 13, 16, 17, 
	18, 18, 5, 6, 13, 5, 13, 13, 
	5, 6, 13, 5, 13, 5, 20, 52, 
	19, 18, 18, 18, 18, 19, 17, 13, 
	53, 13, 13, 13, 13, 13, 13, 13, 
	13, 13, 13, 52, 56, 59, 55, 17, 
	56, 56, 13, 14, 13, 53, 13, 13, 
	5, 13, 13, 13, 13, 13, 17, 54, 
	13, 5, 19, 13, 49, 13, 13, 16, 
	18, 18, 5, 6, 13, 5, 13, 13, 
	5, 17, 13, 53, 13, 13, 13, 13, 
	13, 13, 16, 13, 13, 52, 56, 59, 
	16, 17, 56, 56, 13, 52, 52, 52, 
	52, 52, 19, 52, 52, 52, 52, 52, 
	52, 52, 19, 52, 52, 57, 18, 18, 
	19, 20, 58, 52, 56, 57, 56, 56, 
	52, 6, 13, 55, 13, 13, 55, 13, 
	14, 13, 15, 13, 13, 5, 13, 13, 
	13, 13, 13, 17, 54, 13, 5, 19, 
	13, 59, 13, 13, 16, 18, 18, 5, 
	6, 13, 5, 13, 5, 1, 2, 3, 
	1, 61, 36, 1, 37, 1, 1, 1, 
	1, 38, 34, 41, 1, 43, 9, 44, 
	1, 40, 42, 42, 0, 6, 22, 5, 
	6, 23, 6, 6, 7, 6, 6, 6, 
	6, 6, 21, 63, 6, 7, 26, 25, 
	64, 6, 24, 25, 25, 7, 8, 7, 
	6, 6, 7, 8, 7, 6, 6, 7, 
	34, 45, 1, 61, 62, 1, 1, 1, 
	1, 1, 1, 40, 38, 33, 8, 69, 
	40, 34, 66, 66, 1, 33, 67, 33, 
	26, 33, 43, 33, 33, 33, 33, 68, 
	33, 33, 32, 33, 70, 42, 42, 43, 
	62, 12, 12, 12, 12, 12, 34, 45, 
	1, 61, 62, 1, 1, 39, 1, 1, 
	1, 1, 38, 1, 33, 8, 69, 65, 
	34, 66, 66, 1, 1, 2, 3, 1, 
	35, 36, 1, 37, 1, 1, 1, 1, 
	38, 34, 41, 1, 43, 9, 69, 1, 
	40, 42, 42, 0, 71, 66, 70, 66, 
	66, 33, 1, 65, 1, 65, 1, 1, 
	8, 9, 14, 13, 15, 13, 5, 13, 
	13, 13, 13, 13, 17, 54, 13, 5, 
	19, 13, 49, 13, 13, 16, 18, 18, 
	5, 8, 10, 11, 8, 74, 7, 8, 
	9, 8, 8, 8, 8, 8, 28, 75, 
	8, 32, 8, 72, 8, 30, 31, 31, 
	9, 1, 8, 9, 28, 73, 8, 74, 
	6, 8, 8, 8, 8, 8, 8, 30, 
	8, 27, 77, 81, 30, 28, 77, 77, 
	8, 27, 78, 27, 26, 27, 32, 27, 
	27, 27, 27, 27, 27, 27, 27, 27, 
	79, 31, 31, 32, 6, 13, 13, 13, 
	13, 12, 13, 80, 33, 79, 77, 77, 
	27, 8, 76, 8, 1, 76, 8, 8, 
	10, 11, 8, 29, 7, 8, 9, 8, 
	8, 8, 8, 8, 28, 75, 8, 32, 
	8, 81, 8, 30, 31, 31, 9, 6, 
	22, 5, 6, 82, 6, 6, 7, 6, 
	6, 6, 6, 6, 21, 63, 6, 7, 
	26, 6, 64, 6, 24, 25, 25, 7, 
	21, 13, 6, 82, 6, 6, 6, 6, 
	6, 6, 24, 6, 6, 20, 84, 87, 
	24, 21, 84, 84, 6, 20, 19, 20, 
	20, 20, 26, 20, 20, 20, 20, 20, 
	20, 20, 26, 20, 20, 85, 25, 25, 
	26, 27, 86, 20, 84, 85, 84, 84, 
	20, 8, 6, 83, 6, 6, 83, 6, 
	6, 22, 5, 6, 23, 6, 6, 7, 
	6, 6, 6, 6, 6, 21, 63, 6, 
	7, 26, 6, 87, 6, 24, 25, 25, 
	7, 0
];

static const ubyte[] _sendero_view_compile_trans_actions = [
	0, 0, 0, 23, 0, 0, 9, 11, 
	19, 15, 13, 17, 21, 0, 0, 0, 
	0, 0, 0, 0, 1, 1, 1, 0, 
	0, 0, 0, 27, 0, 0, 0, 70, 
	0, 0, 0, 70, 0, 0, 0, 0, 
	0, 23, 0, 0, 9, 11, 19, 15, 
	13, 17, 21, 0, 0, 0, 29, 0, 
	0, 0, 0, 1, 1, 1, 0, 0, 
	29, 0, 0, 0, 0, 0, 23, 0, 
	0, 9, 11, 19, 15, 13, 17, 21, 
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 1, 0, 0, 0, 0, 0, 0, 
	0, 27, 0, 0, 0, 23, 0, 0, 
	9, 11, 19, 15, 13, 17, 21, 0, 
	0, 0, 70, 0, 1, 0, 0, 0, 
	1, 1, 1, 0, 0, 23, 0, 0, 
	9, 11, 19, 15, 13, 17, 21, 0, 
	0, 0, 70, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 0, 0, 0, 70, 
	0, 0, 0, 70, 0, 0, 0, 37, 
	0, 175, 0, 37, 0, 23, 0, 0, 
	9, 11, 19, 15, 13, 17, 21, 0, 
	70, 0, 0, 0, 0, 0, 1, 0, 
	1, 1, 0, 34, 34, 170, 34, 0, 
	0, 0, 34, 25, 7, 3, 5, 161, 
	25, 25, 25, 61, 25, 40, 43, 55, 
	49, 46, 52, 3, 58, 5, 67, 25, 
	31, 25, 31, 25, 31, 31, 25, 0, 
	0, 0, 23, 0, 0, 9, 11, 19, 
	15, 13, 17, 21, 0, 29, 0, 0, 
	0, 0, 1, 0, 1, 1, 0, 0, 
	0, 29, 0, 0, 0, 0, 29, 0, 
	0, 37, 0, 81, 0, 37, 34, 77, 
	34, 0, 0, 0, 34, 25, 7, 3, 
	5, 67, 25, 25, 25, 61, 25, 25, 
	40, 43, 55, 49, 46, 52, 3, 58, 
	5, 25, 31, 25, 31, 25, 31, 31, 
	25, 0, 0, 0, 23, 0, 0, 9, 
	11, 19, 15, 13, 17, 21, 0, 0, 
	0, 0, 0, 1, 0, 1, 1, 0, 
	0, 0, 0, 0, 37, 0, 37, 34, 
	0, 0, 0, 34, 7, 3, 5, 25, 
	25, 25, 25, 61, 25, 25, 40, 43, 
	55, 49, 46, 52, 3, 58, 5, 25, 
	25, 25, 31, 25, 31, 31, 25, 0, 
	0, 0, 23, 0, 0, 9, 11, 19, 
	15, 13, 17, 21, 0, 0, 0, 0, 
	0, 1, 0, 1, 1, 0, 0, 0, 
	0, 29, 0, 0, 0, 0, 0, 23, 
	0, 0, 9, 11, 19, 15, 13, 17, 
	21, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 0, 0, 0, 23, 
	0, 0, 9, 11, 19, 15, 13, 17, 
	21, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 0, 0, 37, 0, 
	0, 0, 0, 0, 0, 34, 7, 3, 
	5, 25, 0, 0, 0, 23, 0, 9, 
	11, 19, 15, 13, 17, 21, 0, 0, 
	0, 27, 0, 0, 0, 0, 0, 1, 
	1, 1, 0, 0, 0, 0, 70, 0, 
	0, 70, 0, 0, 0, 23, 0, 0, 
	9, 11, 19, 15, 13, 17, 21, 0, 
	70, 0, 1, 0, 0, 0, 1, 0, 
	1, 1, 0, 0, 0, 70, 0, 0, 
	0, 0, 0, 70, 0, 0, 34, 34, 
	170, 0, 0, 0, 0, 34, 25, 61, 
	25, 40, 43, 55, 49, 46, 52, 3, 
	58, 5, 161, 25, 31, 25, 31, 25, 
	31, 31, 25, 0, 23, 0, 0, 9, 
	11, 19, 15, 13, 17, 21, 0, 0, 
	0, 70, 0, 0, 0, 0, 0, 1, 
	1, 1, 0, 0, 0, 70, 0, 0, 
	0, 37, 153, 37, 97, 105, 137, 121, 
	113, 129, 0, 145, 175, 37, 73, 37, 
	1, 37, 73, 73, 37, 34, 34, 149, 
	34, 93, 101, 133, 117, 109, 125, 141, 
	34, 34, 170, 34, 34, 1, 1, 1, 
	34, 165, 34, 197, 37, 0, 37, 37, 
	165, 157, 89, 3, 85, 191, 25, 157, 
	0, 23, 0, 0, 9, 11, 19, 15, 
	13, 17, 21, 0, 0, 0, 70, 0, 
	0, 0, 0, 0, 1, 1, 1, 0, 
	0, 0, 70, 0, 0, 0, 0, 0, 
	23, 0, 0, 9, 11, 19, 15, 13, 
	17, 21, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 0, 0, 0, 0, 
	23, 0, 0, 9, 11, 19, 15, 13, 
	17, 21, 0, 0, 0, 29, 0, 1, 
	0, 0, 1, 1, 1, 0, 0, 29, 
	0, 0, 0, 0, 29, 0, 0, 0, 
	37, 37, 153, 37, 37, 97, 105, 137, 
	121, 113, 129, 0, 145, 37, 37, 37, 
	1, 37, 73, 73, 37, 34, 34, 149, 
	34, 93, 101, 133, 117, 109, 125, 141, 
	34, 34, 34, 34, 1, 1, 1, 34, 
	25, 7, 3, 5, 64, 25, 25, 25, 
	61, 25, 25, 40, 43, 55, 49, 46, 
	52, 3, 58, 5, 25, 25, 25, 31, 
	25, 31, 31, 25, 0, 0, 0, 23, 
	0, 0, 9, 11, 19, 15, 13, 17, 
	21, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 34, 37, 0, 37, 
	37, 165, 89, 3, 85, 25, 157, 0, 
	0, 0, 0, 23, 0, 9, 11, 19, 
	15, 13, 17, 21, 0, 0, 0, 27, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	0, 0, 0, 0, 23, 0, 0, 9, 
	11, 19, 15, 13, 17, 21, 0, 0, 
	0, 0, 0, 0, 0, 1, 1, 1, 
	0, 0, 0, 0, 37, 37, 153, 37, 
	37, 97, 105, 137, 121, 113, 129, 0, 
	145, 37, 73, 37, 1, 37, 73, 73, 
	37, 34, 34, 149, 34, 93, 101, 133, 
	117, 109, 125, 141, 34, 34, 34, 34, 
	1, 1, 1, 34, 25, 7, 3, 5, 
	64, 25, 25, 34, 165, 0, 37, 37, 
	165, 89, 3, 85, 157, 25, 157, 0, 
	0, 0, 23, 0, 0, 9, 11, 19, 
	15, 13, 17, 21, 0, 0, 0, 0, 
	0, 0, 0, 1, 1, 1, 0, 0, 
	0, 0, 23, 0, 0, 9, 11, 19, 
	15, 13, 17, 21, 0, 0, 0, 29, 
	0, 0, 0, 0, 1, 1, 1, 0, 
	37, 37, 153, 37, 97, 105, 137, 121, 
	113, 129, 0, 145, 81, 37, 73, 37, 
	1, 37, 73, 73, 37, 34, 34, 149, 
	34, 93, 101, 133, 117, 109, 125, 141, 
	34, 34, 77, 34, 34, 1, 1, 1, 
	34, 165, 34, 185, 37, 0, 37, 37, 
	165, 157, 89, 3, 85, 180, 25, 157, 
	0, 0, 0, 23, 0, 0, 9, 11, 
	19, 15, 13, 17, 21, 0, 0, 0, 
	29, 0, 0, 0, 0, 1, 1, 1, 
	0, 0
];

static const int sendero_view_compile_start = 1;
static const int sendero_view_compile_first_final = 88;
static const int sendero_view_compile_error = 0;

static const int sendero_view_compile_en_main = 1;
static const int sendero_view_compile_en_main_Expression_end_call = 43;

#line 170 "sendero/view/expression/Compile.rl"

/+
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
+/

enum OpT {
	Add = Op.Add,
	Sub = Op.Sub,
	Mul = Op.Mul,
	Div = Op.Div,
	Mod = Op.Mod,
	
	//ExprParen,
	//FuncParen,
	Paren,
	Dot,
	Index
};

void doOp(Fsm fsm, OpT op)
{
	if(!fsm.opSt.empty && fsm.opSt.top <= precedence.length) {
		if(precedence[fsm.opSt.top] < precedence[op]) {
			fsm.opSt.push(OpT.Add);
		}
		else {
			fsm.expr ~= Op(fsm.opSt.top);
			fsm.opSt.pop;
			fsm.opSt.push(op);
		} 
	}
	else fsm.opSt.push(op);
}


class Fsm
{
	this()
	{
		opStack = new Stack!(OpT);
	}

	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
	
	Expr expr;
	Stack!(OpT) opStack;
	alias opStack opSt;
}

void parse(char[] src)
{
	auto fsm = new Fsm;
	char* p = src.ptr;
	char* pe = p + src.length + 1;
	char* eof = pe;
	
#line 608 "sendero/view/expression/Compile.d"
	{
	 fsm.cs = sendero_view_compile_start;
	}
#line 240 "sendero/view/expression/Compile.rl"
	
#line 612 "sendero/view/expression/Compile.d"
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
#line 22 "sendero/view/expression/Compile.rl"
	{fsm.tokenStart = p;}
	break;
	case 1:
#line 24 "sendero/view/expression/Compile.rl"
	{
	Op op;
	op.key = fsm.tokenStart[0 .. p - fsm.tokenStart];
	
	if(fsm.opSt.empty || fsm.opSt.top != OpT.Dot) {
		op.op = Op.Root;
	}
	else {
		op.op = Op.Key;
	}
	fsm.expr ~= op;
	
	fsm.opSt.pop;
	
	debug Stdout.formatln("Found identifier: {}", op.key);
}
	break;
	case 2:
#line 41 "sendero/view/expression/Compile.rl"
	{ Stdout.formatln("Found number: {}", fsm.tokenStart[0 .. p - fsm.tokenStart]); }
	break;
	case 3:
#line 43 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Dot);
	debug Stdout("Found dot step").newline;
}
	break;
	case 4:
#line 47 "sendero/view/expression/Compile.rl"
	{ Stdout("Found index step").newline; }
	break;
	case 5:
#line 48 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Paren);
	Stdout("Found function call").newline;
}
	break;
	case 6:
#line 53 "sendero/view/expression/Compile.rl"
	{
	fsm.opSt.push(OpT.Paren);
}
	break;
	case 7:
#line 56 "sendero/view/expression/Compile.rl"
	{
	while(!fsm.opSt.empty && fsm.opSt.top != OpT.Paren) {
		fsm.expr ~= Op(fsm.opSt.top);
		fsm.opSt.pop;
	}
	{ fsm.cs = 43; if (true) goto _again;}
}
	break;
	case 8:
#line 64 "sendero/view/expression/Compile.rl"
	{
	while(!fsm.opSt.empty && fsm.opSt.top != OpT.Paren) {
		fsm.expr ~= Op(fsm.opSt.top);
		fsm.opSt.pop;
	}
}
	break;
	case 9:
#line 71 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Add); }
	break;
	case 10:
#line 72 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Sub); }
	break;
	case 11:
#line 74 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Mul); }
	break;
	case 12:
#line 75 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Div); }
	break;
	case 13:
#line 76 "sendero/view/expression/Compile.rl"
	{	doOp(fsm, OpT.Mod); }
	break;
	case 14:
#line 120 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 15:
#line 130 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 16:
#line 135 "sendero/view/expression/Compile.rl"
	{p--;}
	break;
	case 17:
#line 140 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
	case 18:
#line 147 "sendero/view/expression/Compile.rl"
	{ ++p; }
	break;
#line 775 "sendero/view/expression/Compile.d"
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
#line 241 "sendero/view/expression/Compile.rl"
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
//	assert(caught);

	
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