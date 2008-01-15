module sendero_controller.Compile;

import tango.io.Stdout;
import tango.io.File;
import tango.io.FileScan;
import Integer = tango.text.convert.Integer;

import sendero.util.StringCharIterator;
import sendero.util.ArrayWriter;
import sendero.util.collection.Stack;

void main(char[][] args)
{
	if(!args.length)
		return;
	
	
     
     void scanFolder(char[] folder)
     {   	 
    	 auto scan = new FileScan;

    	 scan (folder, "*");
    	 
    	 foreach (f; scan.folders)
    	 	scanFolder(f.toString);
    	 
    	 scan (folder, ".dc");
         
         foreach (file; scan.files) {
        	 Stdout.formatln("Converting {}", file);
         	convertFile(file.toString[0 .. $ - 3]);
         }
     }
     
     scanFolder(args[1]);
}

const ubyte A = 1;
const ubyte N = 2;

const ubyte lookup[256] = 
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 0
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 2
         N,  N,  N,  N,  N,  N,  N,  N,  N,  N,  0,  0,  0,  0,  0,  0,  // 3
         0,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 4
         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  0,  0,  0,  0,  A,  // 5
         0,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  // 4
         A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  A,  0,  0,  0,  0,  0,  // 7
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 8
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 9
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // A
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // B
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // C
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // D
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // E
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   // F
    ];

const char[] routerDecl = "\tstatic const Router r;\n"
	"\tstatic Response route(Request req)\n"
	"\t{\n"
		"\t\treturn r.route(req);\n"
	"\t}\n\n";

void convertFile(char[] filename)
{
	auto f = new File(filename ~ ".dc");
	if(!f) throw new Exception("Unable to open file " ~ filename ~ ".dc");
	
	auto src = cast(char[])f.read;
	
	auto itr = new StringCharIterator!(char)(src);
	
	auto res = new ArrayWriter!(char);
	
	uint lineNo = 0;
	
	void error(char[] msg)
	{
		Stdout.formatln("{}({}): {}", filename ~ ".dc", lineNo, msg);
	}
	
	void eatSpace()
	{
		while(itr.good) {
			switch(itr[0])
			{
			case ' ':
			case '\t':
			case '\r':
				break;
			case '\n':
				++lineNo;
				break;
			default:
				return;
			}
			++itr;
		}
	}
	
	void eatString()
	{
		while(itr.good) {
			if(itr[0] == '"') {
				if(itr[-1] != '\\')
					return;
			}
			++itr;
		}
	}
	
	char[] getToken()
	{
		if(lookup[itr[0]] != A) {
			error("Expected token");
			return null;
		}
		
		auto start = itr.location;
		while(itr.good && lookup[itr[0]] >= A) {++itr;}
		
		return itr.randomAccessSlice(start, itr.location);
	}	
	
	bool doController()
	{
		struct DeclParam
		{
			char[] type;
			char[] name;
		}
		
		struct ActionDecl
		{
			enum : ubyte { Standard, Wildcard, Default };
			ubyte type = Standard;
			char[] method;
			char[] name;
			DeclParam[] params;
		}
		
		ActionDecl[] actions;
		
		
		itr += 10;
		
		res ~= "class ";
		
		eatSpace;

		auto name = getToken;
		if(!name) return false;
		
		res ~= name ~ "\n{\n";
		
		res ~= routerDecl;
		
		eatSpace;
		
		if(itr[0] != '{') {
			error("Expected { at start of controller, found " ~ itr[0]);
			return false;
		}
		++itr;
		
		bool expectGET_POST()
		{
			error("expected GET, POST, or ALL at beginning of action declaration");
			return false;
		}
		
		while(itr.good) {
			ActionDecl decl;
			
			eatSpace;
			
			if(itr[0] == '}') break;
			
			switch(itr[0])
			{
			case 'G':
				if(itr[0 .. 3] != "GET") return expectGET_POST;
				itr += 3;
				decl.method = "GET";
				break;
			case 'P':
				if(itr[0 .. 4] != "POST") return expectGET_POST;
				itr += 4;
				decl.method = "POST";
				break;
			case 'A':
				if(itr[0 .. 3] != "ALL") return expectGET_POST;
				itr += 3;
				decl.method = "ALL";
				break;
			default:
				return expectGET_POST;
			}
			
			eatSpace;
			
			char x = itr[0];
			if(x == '*') {
				decl.name = "__wildcard__";
				decl.type = ActionDecl.Wildcard;
				++itr;
			}
			else if(x == '/') {
				decl.name = "__default__";
				decl.type = ActionDecl.Default;
				++itr;
			}
			else {
				decl.name = getToken;
			}
			
			res ~= "#line " ~ Integer.toString(lineNo) ~ " \"" ~ filename ~ ".dc\"\n";
			res ~= "\tstatic Response " ~ decl.name;
			
			eatSpace;
			
			auto begDecl = itr.location;
			
			if(itr[0] != '(') {
				error("Expected ( in action declaration, found " ~ itr[0]);
				return false;
			}
			++itr;
			
			while(itr.good) {
				eatSpace;
				
				if(itr[0] == ')') {
					++itr;
					break;
				}
				
				auto begType = itr.location;
				while(itr[0] > 32) {
					++itr;
				}
				
				char[] type = itr.randomAccessSlice(begType, itr.location);
			
				eatSpace;
				
				auto varName = getToken;
				
				DeclParam p;
				p.type = type;
				p.name = varName;
				decl.params ~= p;
				
				eatSpace;
				
				if(itr[0] == ')') {
					++itr;
					break;
				}
				else if(itr[0] == ',') {
					++itr;
				}
				else {
					error("Unexpected token in action declaration " ~ itr[0]);
					return false;
				}
			}
			
			actions ~= decl;
			
			eatSpace;
			
			res ~= itr.randomAccessSlice(begDecl, itr.location);
			
			if(itr[0] != '{') {
				error("Expected { at start of action, found " ~ itr[0]);
				return false;
			}
			
			auto start = itr.location;
			++itr;
		
			auto stack = new Stack!(char);
			stack.push('}');
					
			while(itr.good && !stack.empty) {
				if(itr[0] == stack.top) {
					stack.pop;
				}
				else {
					switch(itr[0])
					{
					case '{':
						stack.push('}');
						break;
					case '[':
						stack.push(']');
						break;
					case '(':
						stack.push(')');
						break;
					case '"':
						eatString;
						break;
					case '\n':
						++lineNo;
						break;
					default:
						break;
					}
				}
				++itr;
			}
			
			eatSpace;
			
			res ~= itr.randomAccessSlice(start, itr.location);
			
			if(itr[0] == '}')
				break;
		}
		
		if(itr[0] != '}') {
			error("Expected } at end of controller, found " ~ itr[0]);
			return false;
		}
		
		res ~= "\n\tstatic this()\n"
				"\t{\n"		
				"\t\tr = Router();\n";
				
		foreach(decl; actions)
		{
			char[] dgName = "&" ~ name ~ "." ~ decl.name;
			res ~= "\t\t" ~ "r.map!(typeof(" ~ dgName ~ "))(" ~ decl.method ~ ", \"";
			switch(decl.type)
			{
			case ActionDecl.Default:
				break;
			case ActionDecl.Wildcard:
				res ~= "*";
				break;
			default:
				res ~= decl.name;
				break;
			}
			res ~= "\", " ~ dgName ~", [";
			bool first = true;
			foreach(p; decl.params)
			{
				if(!first) res ~= " ,";
				res ~= "\"";
				res ~= p.name;
				res ~= "\"";
				first = false;
			}
			res ~= "]);\n";
		}
				
		res ~= "\t}\n";
		
		return true;
	}
	
	void doMain()
	{
		auto start = itr.location;
		
		while(itr.good) {
			switch(itr[0])
			{
			case 'c':
				if(itr[0 .. 10] == "controller") {
					res ~= itr.randomAccessSlice(start, itr.location - 1);
					if(!doController) return;
					start = itr.location;
				}
				break;
			case '\n': 
				++lineNo;
				break;
			default:
				break;
			}
			++itr;		
		}
		
		res ~= itr.randomAccessSlice(start, itr.length);
	}
	
	doMain;
	
	auto of = new File(filename ~ ".d");
	of.write(cast(void[])res.get);
	
	Stdout.formatln("Saving {}", filename ~ ".d");
}

