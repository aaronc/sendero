module sendero.view.expression.Compile;

import tango.io.Stdout;

%%{
machine sendero_view_compile;

access fsm.;

action do_start_id {fsm.tokenStart = fpc;}
action do_end_id {Stdout(fsm.tokenStart[0 .. fpc - fsm.tokenStart]);}
action emit { Stdout(fc); }

Identifier = [a-zA-Z_][a-zA-Z_0-9]*;

AccessStep = ('.' Identifier);

##OpIndex = '[' Expression ']';

VarAccess = Identifier AccessStep*;

Whitespace = space*;

Operator = '+';
Atom = VarAccess;

Expression = 
start:(
	##Identifier >start_id %end_id -> start |
	[a-zA-Z_] @do_start_id -> identifier |
	Whitespace -> start
),
identifier: (
	[a-zA-Z_0-9] -> identifier |
	[.] @do_end_id -> start |
	[^a-zA-Z_0-9\.] @do_end_id -> start
);

##Atom (Whitespace Atom)*;

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
	parse("test one test ");
}

}