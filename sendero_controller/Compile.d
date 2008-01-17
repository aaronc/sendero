module sendero_controller.Compile;

import tango.util.ArgParser;
import tango.io.Stdout;
import tango.io.File;
import tango.io.FilePath;
import tango.io.FileScan;
import Integer = tango.text.convert.Integer;
import Util = tango.text.Util;

import sendero.util.StringCharIterator;
import sendero.util.ArrayWriter;
import sendero.util.collection.Stack;

struct GenParams
{
	char[] resType = "char[]";
	char[] reqType = "Request";
	char[] addImport = "import sendero.routing.Request;";
}

const char[] sccVer = "0.0.1";

void main(char[][] arguments)
{
	Stdout.formatln("Sendero Controller Compiler v{}", sccVer);
	Stdout.formatln("Copyright (c) 2008 Aaron Craelius");
	
	char[] folder;
	GenParams gParams;
	
	auto argp = new ArgParser((char[] val, uint i) { if(i == 1) folder = val; });
	argp.bind(
			[Argument("-", "r"), Argument("--", "res_type")],
			(char[] val) {
				gParams.resType = val;
			});
	argp.bind(
			[Argument("-", "q"), Argument("--", "req_type")],
			(char[] val) {
				gParams.reqType = val;
			});
	argp.bind(
			[Argument("-", "i"), Argument("--", "import")],
			(char[] val) {
				auto f = new File(val);
				if(f) {
					gParams.addImport = cast(char[])f.read;
				}
			});
	argp.parse(arguments);
	if(!folder.length) folder = ".";
		
	//scanFolder(arguments[1], gParams);
	CtlrInfo info;
	convertFile(arguments[1], gParams, info);
	
	Stdout("Done compiling controllers").newline.newline;
}

/+void scanFolder(char[] folder, GenParams gParams)
{   	 
	 auto scan = new FileScan;

	 scan (folder, "*");
	 
	 foreach (f; scan.folders)
	 	scanFolder(f.toString, gParams);
	 
	 scan (folder, ".dc");
    
    foreach (file; scan.files) {
   	 	Stdout.formatln("Converting {}", file);
   	 	CtlrInfo info;
    	convertFile(file.toString[0 .. $ - 3], gParams, info);
    }
}+/

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
	char[] importedRoute;
	char[] pathName;
	char[][] pathAliases;
	
	char[] doParamStr(GenParams gParams)
	{
		char[] res;
		bool first = true;
		foreach(p; params)
		{
			if(p.type == gParams.reqType)
				continue;
			
			if(!first) res ~= " ,";
			res ~= "\"";
			res ~= p.name;
			res ~= "\"";
			first = false;
		}
	
		return res;
	}
}

struct CtlrDecl
{
	ActionDecl[] actions;
	char[] name;
	uint joinPt;
	bool instanceCtlr;
}

struct CtlrInfo
{
	CtlrDecl[] decls;
	CtlrInfo[] imports;
	
	bool lookupRoute(char[] path, GenParams gParams, inout char[] dgName, inout char[] paramStr, inout char[] err)
	{
		auto tokens = Util.split(path, ".");
		if(tokens.length == 1) {
			dgName = "&" ~ tokens[0] ~ ".route";
			paramStr = "";
			return true;
		}
		else if(tokens.length == 2) {
			foreach(decl; decls)
			{
				if(decl.name == tokens[0])
				{
					foreach(action; decl.actions)
					{
						if(action.name == tokens[1])
						{
							dgName = "&" ~ path;
							paramStr = action.doParamStr(gParams);
							return true;
						}
					}
				}
			}
			
			foreach(ctlr; imports)
			{
				if(ctlr.lookupRoute(path, gParams, dgName, paramStr, err))
					return true;
			}
			
			err = "Unable to find route " ~ path;
			
			return false;
		}
		else {
			err = "Too many tokens in route " ~ path;
			return false;
		}
	}
}

void convertFile(char[] filename, GenParams gParams, inout CtlrInfo info)
{
	auto f = new File(filename ~ ".dc");
	if(!f) throw new Exception("Unable to open file " ~ filename ~ ".dc");
	
	auto src = cast(char[])f.read;
	
	auto itr = new StringCharIterator!(char)(src);
	
	auto res = new ArrayWriter!(char);
	
	uint lineNo = 0;
	bool firstCtlr = true;
	
	void error(char[] msg)
	{
		Stdout.formatln("{}({}): {}", filename ~ ".dc", lineNo + 1, msg);
	}
	
	char[] printLineDecl() {
		return "#line " ~ Integer.toString(lineNo) ~ " \"" ~ filename ~ ".dc\"\n";
	}
	
	res ~= printLineDecl;
	
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
	
	char[] eatString()
	{
		auto strbeg = itr.location;
		while(itr.good) {
			if(itr[0] == '"') {
				if(itr[-1] != '\\')
					return itr.randomAccessSlice(strbeg, itr.location);
			}
			++itr;
		}
		return "";
	}
	
	bool doComment()
	{
		if(itr[0 .. 2] == "//") {
			itr.forwardLocate('\n');
			++lineNo;
			++itr;
			return true;				
		}
		else if(itr[0 .. 2] == "/*") {
			while(itr.good) {
				if(itr[0] == '*') {
					if(itr[1] == '/') {
						itr += 2;
						return true;
					}
				}
				else if(itr[0] == '\n') {
					++lineNo;
				}
				++itr;
			}
			error("Unterminated comment, expected */");
			return false;
		}
		else if(itr[0 .. 2] == "/+") {
			itr += 2;
			uint depth = 1;
			while(itr.good) {
				if(itr[0] == '+') {
					if(itr[1] == '/') {
						itr += 2;
						--depth;
						if(depth == 0)
							return true;
					}
				}
				else if(itr[0] == '/') {
					if(itr[1] == '+') {
						itr += 2;
						++depth;
					}
				}
				else if(itr[0] == '\n') {
					++lineNo;
				}
				++itr;
			}
			error("Unterminated nested comment, expected proper nesting of /+ and +/");
			return false;
		}
		else {
			return false;
		}
	
	}
	
	char[] getToken()
	{
		if(lookup[itr[0]] != A) {
			error("Expected token");
			return null;
		}
		
		auto tknbeg = itr.location;
		while(itr.good && lookup[itr[0]] >= A) {++itr;}
		
		return itr.randomAccessSlice(tknbeg, itr.location);
	}	
	
	alias void delegate() HookFn;
	
	char[] getBody(HookFn hookFn = null)
	{	
		auto bodyBeg = itr.location;
		auto stack = new Stack!(char);
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
		default: assert(false);
		}
		++itr;
		
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
				case '/':
					if(doComment)
						continue;
					break;
				case '\n':
					++lineNo;
					break;
				default:
					if(hookFn !is null) hookFn();
					break;
				}
			}
			++itr;
		}
		
		eatSpace;
		
		auto res = itr.randomAccessSlice(bodyBeg, itr.location);
		return res;
	}
	
	char[] doDecl(inout ActionDecl decl)
	{		
		auto begDecl = itr.location;
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
				return null;
			}
		}
		
		eatSpace;
		
		return itr.randomAccessSlice(begDecl, itr.location);
	}
	
	char[] doRouting(CtlrDecl cd)
	{
		auto txt = new ArrayWriter!(char);
		
		foreach(decl; cd.actions)
		{
			if(decl.method == "")
				continue;
			
			char[] dgName;
			char[] paramStr;
			
			if(decl.importedRoute.length) {
				char[] err;
				if(!info.lookupRoute(decl.importedRoute, gParams, dgName, paramStr, err)) {
					error(err);
					return null;
				}
			}
			else {
				dgName = "&" ~ cd.name ~ "." ~ decl.name;
				paramStr = decl.doParamStr(gParams);
			}
			
			void doMapping(char[] path)
			{
				txt ~= "\t\tr.map!(typeof(" ~ dgName ~ "))(" ~ decl.method ~ ", \"";
				txt ~= path;
				txt ~= "\", ";
				txt ~= dgName ~ ", [" ~ paramStr ~ "]);\n";
			}
			
			if(decl.method == "__error__") {
				txt ~= "\t\tr.setErrorHandler!(typeof(" ~ dgName ~ "))(";
				txt ~= dgName ~ ", [" ~ paramStr ~ "]);\n";
			}
			else {
				doMapping(decl.pathName);
				foreach(path; decl.pathAliases) doMapping(path);
			}
			
		}
		
		return txt.get;
	}
	
	char[] stripSpaces(char[] str)
	{
		auto res = Util.strip(str, ' ');
		res = Util.strip(res, '\t');
		return res;
	}
	
	bool doImport()
	{
		itr += 6;
		eatSpace;
		auto start = itr.location;
		if(!itr.forwardLocate(';')) {
			error("Expected token and ; after import");
			return false;
		}
		auto path = stripSpaces(itr.randomAccessSlice(start, itr.location).dup);
		path = Util.replace(path, '.', '/');
		CtlrInfo impInfo;
		auto filepath = new FilePath(path ~ ".dc");
		if(filepath.exists) {
			convertFile(path, gParams, impInfo);
			if(impInfo.decls.length)
				info.imports ~= impInfo;
		}
		return true;
	}
	
	bool doController(inout CtlrDecl cDecl, bool instance = false)
	{
		cDecl.instanceCtlr = instance;
		
		if(firstCtlr) {
			firstCtlr = false;
			
			res ~= "\nimport sendero.routing.TypeSafeRouter;\n";
			res ~= gParams.addImport ~ "\n\n";
			res ~= printLineDecl;
		}
		
		
		res ~= "class ";
		
		eatSpace;

		cDecl.name = getToken;
		if(!cDecl.name) return false;
		
		res ~= cDecl.name ~ "\n{\n";
		
		char[] routerDecl(GenParams gParams, bool instance) {
			char[] res = "\tstatic const ";
			res ~= "TypeSafeRouter";
			res ~= "!(" ~ gParams.resType ~ "," ~ gParams.reqType ~ ") r;\n";
			
			if(!instance) {
				res ~= "\tstatic " ~ gParams.resType ~ " route(Request req)\n"
						"\t{\n"
							"\t\treturn r.route(req);\n"
						"\t}\n\n";
			}
			else {
				res ~= "\t" ~ gParams.resType ~ " route(Request req)\n"
				"\t{\n"
					//"\t\tif(ptr is null) throw new Exception(\"icontroller " ~ cDecl.name ~ " access violation\");\n"
					"\t\treturn r.route(req, cast(void*)this);\n"
				"\t}\n\n";
			}
			return res;
		}		
		
		res ~= routerDecl(gParams, instance);
		
		eatSpace;
		
		if(itr[0] != '{') {
			error("Expected { at start of controller, found " ~ itr[0]);
			return false;
		}
		++itr;
		
		bool expectGET_POST()
		{
			error("expected GET, POST, ALL, STATIC, or __error__ at beginning of action declaration");
			return false;
		}
		
		while(itr.good) {
			ActionDecl decl;
			
			void parseCtlr()
			{
				auto stuffbeg = itr.location;
				
				void finish()
				{
					res ~= itr.randomAccessSlice(stuffbeg, itr.location);
				}
				
				while(itr.good)
				{
					switch(itr[0])
					{
					case 'G':
						if(itr[0 .. 3] == "GET") {
							finish;
							itr += 3;
							decl.method = "GET";
							return;
						}
						break;
					case 'P':
						if(itr[0 .. 4] == "POST") {
							finish;
							itr += 4;
							decl.method = "POST";
							return;
						}
						break;
					case 'A':
						if(itr[0 .. 3] == "ALL") {
							finish;
							itr += 3;
							decl.method = "ALL";
							return;
						}
						break;
					case 'S':
						if(itr[0 .. 6] == "STATIC") {
							finish;
							itr += 6;
							decl.method = "";
							return;
						}
						break;
					case '_':
						if(itr[0 .. 9] == "__error__") {
							finish;
							itr += 9;
							decl.method = "__error__";
							return;
						}
						break;
					case '{':
					case '[':
					case '(':
						getBody;
						continue;
					case '"':
						eatString;
						break;
					case '/':
						if(doComment)
							continue;
						break;
					case '\n':
						lineNo++;
						break;
					case '}':
						return finish;
					default:
						break;
					}
					++itr;
				}
				return finish;
			}
			
			parseCtlr;
			
			if(itr[0] == '}')
				break;
			
			eatSpace;
			
			if(decl.method == "__error__") {
				decl.name = "__error__";
			}
			else {
				char x = itr[0];
				if(x == '*') {
					decl.name = "__wildcard__" ~ decl.method;
					decl.pathName = "*";
					decl.type = ActionDecl.Wildcard;
					++itr;
				}
				else if(x == '/') {
					decl.name = "__default__" ~ decl.method;
					decl.pathName = "";
					decl.type = ActionDecl.Default;
					++itr;
				}
				else {
					decl.name = getToken;
					decl.pathName = decl.name;
					if(decl.name == "__default__") {
						decl.pathName = "";
						decl.type = ActionDecl.Default;
					}
					else if(decl.name == "__wildcard__") {
						decl.pathName = "*";
						decl.type = ActionDecl.Wildcard;
					}
				}
			}
			
			eatSpace;
			
			bool expectDecl()
			{
				error("Expected ( or -> in action declaration, found " ~ itr[0]);
				return false;
			}
			
			if(itr[0] == '[') {
				++itr;
				eatSpace;
				if(itr[0] != '"') {
					error("Expected string literal after [ in action path statement");
					return false;
				}
				++itr;
				decl.pathName = eatString;
				++itr;
				eatSpace;
				
				while(itr[0] == ',') {
					++itr;
					eatSpace;
					if(itr[0] != '"') {
						error("Expected \" after comma action path statement");
						return false;
					}
					++itr;
					decl.pathAliases ~= eatString;
					++itr;
					eatSpace;
				}
				
				if(itr[0] != ']') {
					error("Expected ] after string literal in action path statement");
					return false;
				}
				++itr;
				
				eatSpace;
			}
			
			void actionHooks()
			{
				void doRedirect()
				{
					while(itr.good) {
						
					}
				}
				
				switch(itr[0])
				{
				case '-':
					if(itr[1] == '>') {
						//itr += 2;
						//eatSpace;
						//doRedirect;
					}
					break;
				default:
					break;
				}
			}
			
			switch(itr[0])
			{
			case '(':
				res ~= printLineDecl;
				res ~= "\t";
				if(!cDecl.instanceCtlr || decl.method == "") {
					res ~= "static ";
				}
				res ~= gParams.resType ~ " " ~ decl.name;
				res ~= doDecl(decl);
				cDecl.actions ~= decl;
				if(itr[0] != '{') {
					error("Expected { at start of action body, found " ~ itr[0]);
					return false;
				}
				
				res ~= getBody(&actionHooks);
				
				break;
			case '-':
				if(itr[0 .. 2] != "->") {
					return expectDecl;
				}
				itr += 2;
				auto i = itr.location;
				if(!itr.forwardLocate(';')) {
					error("Expected token and ; after ->");
					return false;
				}
				decl.importedRoute = stripSpaces(itr.randomAccessSlice(i, itr.location));
				cDecl.actions ~= decl;
				++itr;
				break;
			default:
				return expectDecl;
			}	
			
			if(itr[0] == '}')
				break;
		}
		
		if(itr[0] != '}') {
			error("Expected } at end of controller, found " ~ itr[0]);
			return false;
		}
		
		res ~= "\n\tstatic this()\n"
				"\t{\n"		
				"\t\tr = TypeSafeRouter!(" ~ gParams.resType ~ "," ~ gParams.reqType ~ ")();\n";
		//res ~= doRouting(cDecl);
		cDecl.joinPt = res.length;
		res ~= "\t}\n";
		
		return true;
	}
	
	void doMain()
	{
		auto start = itr.location;
		
		while(itr.good) {
			switch(itr[0])
			{
			case 'i':
				if(itr[0 .. 6] == "import") {
					if(!doImport) return;
				}
				else if(itr[0 .. 11] == "icontroller") {
					res ~= itr.randomAccessSlice(start, itr.location);
					itr += 11;
					CtlrDecl cDecl;
					if(!doController(cDecl, true)) return;
					info.decls ~= cDecl;
					start = itr.location;
				}
				break;
			case 'c':
				if(itr[0 .. 10] == "controller") {
					res ~= itr.randomAccessSlice(start, itr.location);
					itr += 10;
					CtlrDecl cDecl;
					if(!doController(cDecl)) return;
					info.decls ~= cDecl;
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
	
	char[] join(CtlrDecl[] ctlrs)
	{
		auto src = res.get;
		auto txt = new ArrayWriter!(char);
		uint i = 0;
		
		foreach(ctlr; ctlrs)
		{
			txt ~= src[i .. ctlr.joinPt];
			txt ~= doRouting(ctlr);
			i = ctlr.joinPt;
		}
		
		txt ~= src[i .. $];
		
		return txt.get;
	}
	
	auto of = new File(filename ~ ".d");
	of.write(cast(void[])join(info.decls));
	
	Stdout.formatln("Saving {}", filename ~ ".d");
}

