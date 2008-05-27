module sendero.view.expression.Lex;

import sendero_base.util.collection.Stack;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

import sendero_base.Core;
import sendero.vm.Expression;

struct Lexer
{
	void reset(char[] src)
	{
		cur = src.ptr;
		end = src.ptr + src.length + 1;
	}
	
	char* cur;
	char* end;
	Expression[] varAcc;
	
	enum State { Default, VarAccess };
	
	static struct Lookup
	{
		enum { 	_, /*None*/
				N, /*Number*/
				A, /*Alpha*/
				O, /*Operator*/
				Q, /*Quote*/
				B, /*Block*/
				D, /*Decorator*/
				S, /*Space*/
				Z, /*Special*/
		};
		const static ubyte table[128] =
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         _,  _,  _,  _,  _,  _,  _,  _,  _,  S,  _,  S,  S,  _,  _,  _,  // 0
		         _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  // 1
		         S,  O,  Q,  Z,  O,  O,  O,  Q,  B,  B,  O,  O,  O,  O,  O,  O,  // 2
		         N,  N,  N,  N,  N,  N,  N,  N,  N,  N,  O,  O,  O,  O,  O,  O,  // 3
		         D,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 4
		         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  B,  O,  B,  O,  A,  // 5
		         Q,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 6
		         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  B,  O,  B,  O,  _,	 // 7
		    ]; 
	}
	alias Lookup.table lookup;
	
	void parse()
	{		
		int lkp;
		while(cur < end) {
			lkp = lookup[*cur];
			switch(lkp)
			{
			case Lookup.N:
				break;
			case Lookup.A:
				auto start = cur;
				while (cur < end) {
					lkp = lookup[*cur];
					if(!(lkp == Lookup.A || lkp == Lookup.N))
						break;
					++cur;
				}
				auto len = cur - start;
				Var id; id.type = VarT.String;
				id.string_ = start[0 .. len];
				varAcc ~= new Literal(id);
				break;
/+			case Lookup.O:
				/+if(ch == '/') {
					auto next = itr[1];
					if(next == '*') {
						while(CCommentTest(itr) && itr.good) itr++;
						itr++;
						break;
					}
					else if(next == '/') {
						itr.goToEOL;
						break;
					}
					else if(next == '+') {
						itr++;
						DNestedCommentTest tester;
						while(tester(itr) && itr.good) itr++;
						itr++;
						break;
					}
				}
				
				this.cur.tokens ~= getToken!(OperatorTest)(itr, Token.Token, 1);+/
				break;
			case Lookup.Q:
				switch(ch)
				{
				case '"': 
					break;
				case '\'': 
					break;
				case '`': t = getToken!(BackTickStringTest)(itr, Token.String);	break;
				default: assert(false, "Unexpected Quote char " ~ ch);
				}
				this.cur ~= t;
				break;
			case Lookup.B:
				switch(ch)
				{
				//case '[': this.pushBlock(Block.Terminator.Square, itr); break;
				//case '(': this.pushBlock(Block.Terminator.Paren, itr);	break;
				//case ')': this.popBlock(Block.Terminator.Paren, itr); break;
				//case ']': this.popBlock(Block.Terminator.Square, itr); break;
				default:
					assert(false);
				}
				break;+/
			case Lookup.S:
			default:
				break;
			}
		}
	}
}

debug(SenderoBaseUnittest)
{
	unittest
	{
		Lexer lex;
		lex.reset("test");
		lex.parse;
	}
}

/+
class Block
{
	enum Terminator {Paren, Square, Expr};
	Terminator terminator;
	Token[] tokens;
	Block parent;
	
	size_t start;
	size_t end;
	char[] src;
	
	void opCatAssign(Token token)
	{
		tokens ~= token;
	}
	
	this()
	{
		this.terminator = Terminator.Expr;
		this.parent = null;
		this.start = 0;
	}
	
	this(Block parent, Terminator term, LexItr itr)
	{
		this.parent = parent;
		this.terminator = term;
		this.start = itr.index;
	}
	
	void finish(LexItr itr)
	{
		this.end = itr.index;
		this.src = itr.src[this.start .. this.end + 1];
	}
	
	debug
	{
		char[] print(uint indent = 0)
		{
			char[] res;
			char[] tab;
			for(uint i = 0; i < indent; ++i)
				tab ~= "\t"; 
			
			res ~= tab ~ "BeginBlock ";
			switch(terminator)
			{
			case Terminator.Curly: res ~= "{"; break;
			case Terminator.Paren: res ~= "("; break; 
			case Terminator.Square: res ~= "["; break;
			case Terminator.Module: res ~= "Module"; break;
			default: assert(false);
			}
			res ~= "\n";
			
			foreach(t; tokens)
			{
				res ~= t.print(indent + 1) ~ "\n";
			}
			
			res ~= tab;
			switch(terminator)
			{
			case Terminator.Curly: res ~= "}"; break;
			case Terminator.Paren: res ~= ")"; break; 
			case Terminator.Square: res ~= "]"; break;
			case Terminator.Module: res ~= "Module"; break;
			default: assert(false);
			}
			res ~= " EndBlock";
			
			return res;
		}
	}
}

struct Token
{
	union
	{
		Block block;
		char[] value;
	}
	enum {Block, Word, Number, Token, String, Decorator};
	int type;
	size_t lineNo;
	
	debug
	{
		char[] print(uint indent = 0)
		{
			char[] res;
			
			void printVal(char[] type)
			{
				for(uint i = 0; i < indent; ++i)
					res ~= "\t";
				res ~= type ~ " ";
				res ~= value;
			}
			
			switch(type)
			{
			case Block: res ~= block.print(indent); break;
			case Word: printVal("Word"); break;
			case Number: printVal("Number"); break;
			case String: printVal("String"); break;
			case Token: printVal("Token"); break;
			default: assert(false);
			}
			return res;
		}
	}
}

class Lexer
{
	this()
	{
		reset;
	}
	
	Block cur;
	Block root;
	
	void pushBlock(Block.Terminator term, LexItr itr)
	{
		auto childBlock = new Block(cur, term, itr);
		Token t;
		t.type = Token.Block;
		t.block = childBlock;
		cur ~= t;
		cur = childBlock;
	}
	
	void popBlock(Block.Terminator term, LexItr itr)
	{
		assert(this.cur.terminator == term && this.cur.parent);
		this.cur.finish(itr);
		this.cur = this.cur.parent;
	}
	
	static Block parse(char[] src)
	{
		auto itr = new LexItr(src);
		auto lexer = new Lexer;
		lexer.parse(itr);
		return lexer.root;
	}
	
	void reset()
	{
		root = cur = new Block;
	}
	
	void parse(LexItr itr)
	{
		while(itr.good) {
			this.step(itr);
			itr++;
		}
	}
	
	static struct Lookup
	{
		enum { 	_, /*None*/
				N, /*Number*/
				A, /*Alpha*/
				O, /*Operator*/
				Q, /*Quote*/
				B, /*Block*/
				D, /*Decorator*/
				S, /*Space*/
				Z, /*Special*/
		};
		const static ubyte table[128] =
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         _,  _,  _,  _,  _,  _,  _,  _,  _,  S,  _,  S,  S,  _,  _,  _,  // 0
		         _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  _,  // 1
		         S,  O,  Q,  Z,  O,  O,  O,  Q,  B,  B,  O,  O,  O,  O,  O,  O,  // 2
		         N,  N,  N,  N,  N,  N,  N,  N,  N,  N,  O,  O,  O,  O,  O,  O,  // 3
		         D,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 4
		         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  B,  O,  B,  O,  A,  // 5
		         Q,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 6
		         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  B,  O,  B,  O,  _,	 // 7
		    ]; 
	}
	alias Lookup.table lookup;
	
	void parse()
	{
		//auto ch = itr[0];
		//auto lkp = lookup[ch];
		char* cur;
		char* end;
		
		while(cur < end) {
			switch(lkp)
			{
			case Lookup.N:
				this.cur.tokens ~= getToken!(NumberTest)(itr, Token.Number, 1);
				break;
			case Lookup.A:
				this.cur.tokens ~= getToken!(WordTest)(itr, Token.Word, 1);
				break;
			case Lookup.O:
				if(ch == '/') {
					auto next = itr[1];
					if(next == '*') {
						while(CCommentTest(itr) && itr.good) itr++;
						itr++;
						break;
					}
					else if(next == '/') {
						itr.goToEOL;
						break;
					}
					else if(next == '+') {
						itr++;
						DNestedCommentTest tester;
						while(tester(itr) && itr.good) itr++;
						itr++;
						break;
					}
				}
				
				this.cur.tokens ~= getToken!(OperatorTest)(itr, Token.Token, 1);
				break;
			case Lookup.Q:
				itr++;
				Token t;
				switch(ch)
				{
				case '"': t = getToken!(StringTest!('\"'))(itr, Token.String); break;
				case '\'': t = getToken!(StringTest!('\''))(itr, Token.String); break;
				case '`': t = getToken!(BackTickStringTest)(itr, Token.String);	break;
				default: assert(false, "Unexpected Quote char " ~ ch);
				}
				this.cur ~= t;
				break;
			case Lookup.B:
				switch(ch)
				{
				case '[': this.pushBlock(Block.Terminator.Square, itr); break;
				case '(': this.pushBlock(Block.Terminator.Paren, itr);	break;
				case ')': this.popBlock(Block.Terminator.Paren, itr); break;
				case ']': this.popBlock(Block.Terminator.Square, itr); break;
				default:
					assert(false);
				}
				break;
			case Lookup.D:
				Token t;
				t.type = Token.Decorator;
				t.lineNo = itr.lineNo;
				this.cur ~= t;
				break;
			case Lookup.Z:
				itr.goToEOL;
				break;
			case Lookup.S:
			default:
				break;
			}
		}
	}
	
	static struct WordTest
	{
		static bool opCall(LexItr itr)
		{
			auto lkp = lookup[itr[1]];
			if(lkp == Lookup.A || lkp == Lookup.N) return true;
			return false;
		}
	}

	static struct NumberTest
	{
		static bool opCall(LexItr itr)
		{
			auto ch = itr[1];
			auto lkp = lookup[ch];
			if(lkp == Lookup.N || lkp == Lookup.A) return true;
			else {
				switch(ch)
				{
				case '-':
				case '+':
					lkp = lookup[itr[0]];
					if(lkp == Lookup.A) return true;
					else return false;
					break;
				case '_':
					return true;
				default:
					return false;
				}
			}
			return false;
		}
	}

	static struct OperatorTest
	{
		static bool opCall(LexItr itr)
		{
			auto lkp = lookup[itr[1]];
			if(lkp == Lookup.O) return true;
			return false;
		}
	}

	static struct StringTest(char Quote)
	{
		static bool opCall(LexItr itr)
		{
			if(itr[0] == Quote) {
				if(itr[-1] != '\\') {
					return false;
				}
			}
			return true;
		}
	}

	static struct BackTickStringTest
	{
		static bool opCall(LexItr itr)
		{
			if(itr[0] == '`') return false;
			return true;
		}
	}
	
	static struct CCommentTest
	{
		static bool opCall(LexItr itr)
		{
			if(itr[0] == '/')
				if(itr[-1] == '*')
					return false;
			return true;
		}
	}
	
	static struct DNestedCommentTest
	{
		int depth = 1;
		
		bool opCall(LexItr itr)
		{
			if(itr[0] == '/') {
				if(itr[-1] == '+') {
					--depth;
					if(depth == 0)
						return false;
				}
				else if(itr[1] == '+') {
					++depth;
				}
			}
			return true;
		}
	}

	static Token getToken(Test)(LexItr itr, int type, size_t offset = 0)
	{
		Token t;
		t.type = type;
		t.lineNo = itr.lineNo;
		
		auto start = itr.index;
		while(Test(itr) && itr.good) itr++;
		auto end = itr.index;
		t.value = itr.src[start .. end + offset];
		
		return t;
	}
}

class LexItr
{
	size_t lineNo;
	size_t colNo;
	
	this(char[] src)
	{
		this.src = src;
		this.len = src.length;
		this.index = 0;
	}
	
	private char[] src;
	private size_t len;
	private size_t index;

	final bool good()
	{
		return index < len;
	}
	
	final char opIndex(ptrdiff_t i)
	{
		if((index + i) < len) return src[index + i];
        else return '\0';
	}
	
	void goToEOL()
	{
		auto curLine = lineNo;
		while(curLine == lineNo) opPostInc;
	}
	
	final LexItr opPostInc()
	{
		++index;
		++colNo;
		if(index < len) {
			if(src[index] == '\r') {
				++lineNo;
				colNo = 0;
				++index;
				if(index < len) {
					if(src[index] == '\n') {
						++index;
					}
				}
			}
			else if(src[index] == '\n') {
				++lineNo;
				colNo = 0;
				++index;
			}
		}
		return this;
	}
}

debug(SenderoBaseUnittest)
{
	import tango.io.File;
	import tango.io.Stdout;
	
	import qcf.Regression;
	struct Tester
	{
		static Regression r;
		static this()
		{
			r = new Regression("decorated_d"); 
		}
		
		static char[] getTest(char[] testName)
		{
			scope f = new File("test/decorated_d/" ~ testName ~ ".dd");
			assert(f, testName);
			return cast(char[])f.read;
		}
		
		static void test(char[] testName)
		{
			auto res = Lexer.parse(getTest("test1")).print;
			r.regress(testName ~ ".lex.txt", res);
		}
	}
	alias Tester.test test;
	
	unittest
	{
		test("test1");
	}
}+/