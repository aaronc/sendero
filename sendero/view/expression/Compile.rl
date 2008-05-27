module sendero.view.expression.Compile;

import tango.io.Stdout;

%%{
machine sendero_view_compile;

access fsm.;

action do_start_id {fsm.tokenStart = fpc;}
action do_end_id {Stdout.formatln("Found identifier: {}", fsm.tokenStart[0 .. fpc - fsm.tokenStart]); }
action do_dot_step { Stdout("Found dot step").newline; }
action do_index_step { Stdout("Found index step").newline; }
action do_function_call { Stdout("Found function call").newline; }

num_char = [0-9.];

Expression = 
start:(
	[a-zA-Z_] @do_start_id -> identifier |
	[0-9]  @do_start_id -> number |
	"]" -> end_index_step |
	")" -> start |
	"." @do_dot_step -> start |
	"[" @do_index_step -> start |
	"(" @do_function_call -> start |
	space+ -> start
),
identifier: (
	[a-zA-Z_0-9] -> identifier |
	[^a-zA-Z_0-9] @do_end_id @{fhold;} -> start
),
end_index_step: (
	"(" @do_function_call -> start |
	[^(] -> start
),
number: (
	num_char @do_end_id -> number |
	any -- num_char -> start
)
;

main := Expression;
	
	
}%%

%% write data;

class Fsm
{
	int cs = 0;
	int* stack;
	int top;
	char* tokenStart;
}

void parse(char[] src)
{
	auto fsm = new Fsm;
	char* p = src.ptr;
	char* pe = p + src.length + 1;
	char* eof = pe;
	%% write init;
	%% write exec;
}

debug(SenderoUnittest)
{

unittest
{
	parse("test.one[test2] test3(param1) test4[step](param2)[5] ");
}

}