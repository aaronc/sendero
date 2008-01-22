module sendero.db.Statement;

import dbi.PreparedStatement;

import tango.core.Traits;

import sendero.util.Reflection;

debug import tango.io.Stdout;

struct StatementContainer
{
	static StatementContainer opCall(IPreparedStatement stmt)
	{
		StatementContainer cntr;
		cntr.stmt = stmt;
		return cntr;
	}
	
	private IPreparedStatement stmt;
	private ubyte[] lastResSignature;
	private ubyte[] lastParamSignature;
}

class TypeVisitor
{
	BindType[] types;
	
	void visit(X)(X x, uint index)
	{
		types ~= getBindType!(X)();
	}
}

class Statement
{
	this(StatementContainer container)
	{
		this.inst = container;
	}
	
	private StatementContainer inst;
	
	IPreparedStatement statement()
	{
		inst.lastResSignature = null;
		inst.lastParamSignature = null;
		return inst.stmt;
	}
	
	void prefetchAll()
	{
		inst.stmt.prefetchAll;
	}
	
	static BindType[] getClassStructTypes(T)()
	{
		auto visitor = new TypeVisitor;
		auto t = new T;
		ReflectionOf!(T).visitTuple(t, visitor);
		return visitor.types;
	}
	
	static void*[] bindClassStruct(T)(inout T t)
	{
		auto fields = ReflectionOf!(T).fields;
		
		static if(is(T == class))
			void* start = cast(void*)t;
		else static if(is(T == struct))
			void* start = &t;
		else static assert(false);
		
		void*[] ptrs;
		auto n = fields.length;
		ptrs.length = n;
		for(uint i = 0; i < n; ++i)
		{
			ptrs[i] = fields[i].offset + start;
		}
		
		return ptrs;
	}
	
	template SetPtrs(char[] n)
	{
		const char[] SetPtrs = 
			"static if(T.length > " ~ n ~ ") {"
				"static if (is(typeof(t[" ~ n ~ "]) == BindInfo))"
					"ptrs ~= info.ptrs;"
				"static if(is(typeof(t[" ~ n ~ "]) == class) || is(typeof(t[" ~ n ~ "]) == struct)) {"
					"t[0] = new typeof(t[" ~ n ~ "]);"
					"ptrs ~= bindClassStruct(t[" ~ n ~ "]);"
				"}"
				"else "
					"ptrs ~= &t[" ~ n ~ "];"
			"}";
	}
	
	static void*[] setPtrs(T...)(T t)
	{
		void*[] ptrs;
		
		/+static if(T.length > 0) {
		static if(is(T == class) || is(T == struct)) {
			t[0] = new typeof(t[0]);
			ptrs ~= bindClassStruct(t[0]);
		}
		else
			ptrs ~= &t[0];
		}+/
		
		mixin(SetPtrs!("0"));
		mixin(SetPtrs!("1"));
		mixin(SetPtrs!("2"));
		mixin(SetPtrs!("3"));
		mixin(SetPtrs!("4"));
		mixin(SetPtrs!("5"));
		mixin(SetPtrs!("6"));
		mixin(SetPtrs!("7"));
		mixin(SetPtrs!("8"));
		mixin(SetPtrs!("9"));
		mixin(SetPtrs!("10"));
		mixin(SetPtrs!("11"));
		mixin(SetPtrs!("12"));
		mixin(SetPtrs!("13"));
		mixin(SetPtrs!("14"));
		mixin(SetPtrs!("15"));
		
		static if(T.length > 15) static assert(false);
		
		return ptrs;
	}
	
	static BindType[] setBindTypes(T...)(T t)
	{
		BindType[] types;			
		
		foreach(x; t)
		{
			static if(is(typeof(x) == BindInfo))
				types ~= t.types;
			else static if(is(typeof(x) == class) || is(typeof(x) == struct))
				types ~= getClassStructTypes!(typeof(x))();
			else
				types ~= getBindType!(typeof(x))();
		}
		
		return types;
	}
	
	template CheckBindInfo(char[] n)
	{
		const char[] CheckBindInfo = 
			"static if(T.length > " ~ n ~ " && is(typeof(t[" ~ n ~ "]) == BindInfo)) {"
				"signature ~= t[" ~ n ~ "].types;"
			"}";
	}
	
	bool execute(T...)(T t)
	{
		static if(T.length) {
			void*[] ptrs = setPtrs(t);
			
			ubyte[] signature = cast(ubyte[])T.stringof;
			mixin(CheckBindInfo!("0"));
			mixin(CheckBindInfo!("1"));
			mixin(CheckBindInfo!("2"));
			mixin(CheckBindInfo!("3"));
			mixin(CheckBindInfo!("4"));
			mixin(CheckBindInfo!("5"));
			mixin(CheckBindInfo!("6"));
			mixin(CheckBindInfo!("7"));
			mixin(CheckBindInfo!("8"));
			mixin(CheckBindInfo!("9"));
			mixin(CheckBindInfo!("10"));
			mixin(CheckBindInfo!("11"));
			mixin(CheckBindInfo!("12"));
			mixin(CheckBindInfo!("13"));
			mixin(CheckBindInfo!("14"));
			mixin(CheckBindInfo!("15"));
			
			if(inst.lastParamSignature != signature)
			{
				BindType[] types = setBindTypes(t);
				
				inst.stmt.setParamTypes(types);
				inst.lastParamSignature = signature;
			}
			
			return inst.stmt.execute(ptrs);
		}
		else {
			return inst.stmt.execute;
		}
	}
	
	bool executeEmpty()
	{
		return inst.stmt.execute;
	}
	
	bool fetch(T...)(out T t)
	{
		void*[] ptrs = setPtrs(t);
		
		ubyte[] signature = cast(ubyte[])T.stringof;
		mixin(CheckBindInfo!("0"));
		mixin(CheckBindInfo!("1"));
		mixin(CheckBindInfo!("2"));
		mixin(CheckBindInfo!("3"));
		mixin(CheckBindInfo!("4"));
		mixin(CheckBindInfo!("5"));
		mixin(CheckBindInfo!("6"));
		mixin(CheckBindInfo!("7"));
		mixin(CheckBindInfo!("8"));
		mixin(CheckBindInfo!("9"));
		mixin(CheckBindInfo!("10"));
		mixin(CheckBindInfo!("11"));
		mixin(CheckBindInfo!("12"));
		mixin(CheckBindInfo!("13"));
		mixin(CheckBindInfo!("14"));
		mixin(CheckBindInfo!("15"));
		
		if(inst.lastResSignature != signature)
		{
			BindType[] types = setBindTypes(t);
			
			inst.stmt.setResultTypes(types);
			inst.lastResSignature = signature;
		}
		
		return inst.stmt.fetch(ptrs);
	}
	
	void reset()
	{
		inst.stmt.reset;
	}
	
	ulong getLastInsertID()
	{
		return inst.stmt.getLastInsertID;
	}
	
	char[] getLastErrorMsg()
	{
		return inst.stmt.getLastErrorMsg;
	}
	
	~this()
	{
		reset;
	}
}

bool compare(BindType[] t1, BindType[] t2)
{
	auto len = t1.length;
	if(len != t2.length) return false;
	for(uint i = 0; i < len; ++i)
		if(t1[i] != t2[i]) return false;
	return true;
}

struct BindInfo
{
	BindType[] types;
	void* ptrs;
}

char[] createInsertSql(T, char quote = '\'')(char[][] except = null, char[] tablename = null)
{
	auto fields = getFieldNames!(T)(except);
	if(!tablename.length) tablename = T.stringof;
	return makeInsertSql(tablename, fields, quote);
}

char[] createUpdateSql(T, char quote = '\'')(char[] whereClause, char[][] except = null, char[] tablename = null)
{
	auto fields = getFieldNames!(T)(except);
	if(!tablename.length) tablename = T.stringof;
	return makeUpdateSql(whereClause, tablename, fields, quote);
}

char[] makeInsertSql(char[] tablename, char[][] items, char quote = '\'')
{
	if(!items.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
	
	char[] res = "INSERT into " ~ quote ~ tablename ~ quote ~ " (";
	res ~= makeList(items, quote) ~ ") VALUES(";
	auto len = items.length;
	for(uint i = 0; i < len; ++i)
	{
		res ~= "?,";
	}
	res[$ - 1] = ')';
	return res;
}

char[] makeUpdateSql(char[] whereClause, char[] tablename, char[][] fields, char quote = '\'')
{
	if(!fields.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
	
	char[] res = "UPDATE '" ~ quote ~ tablename ~ quote ~ "' SET ";
	foreach(f; fields)
	{
		res ~= quote ~ f ~ quote ~ "=\?,";
	}
	res[$-1] = ' ';
	if(whereClause.length) res ~= whereClause;
	return res;
}

char[] makeList(char[][] items, char quote = '\'')
{
	char[] res;
	
	foreach(x; items)
	{
		res ~= quote ~ x ~ quote ~ ",";
	}
	
	return res[0 .. $ - 1];
}

char[] createFieldList(T)(char[][] except)
{
	auto fields = getFieldNames!(T)(except);
	returen makeList(fields);
}

char[][] getFieldNames(T)(char[][] except)
{
	char[][] res;
	auto fields = ReflectionOf!(T).fields;
	auto len = fields.length;
	for(uint i = 0; i < len; ++i)
	{
		bool skip = false;
		foreach(n; except) if(fields[i].name == n) skip = true;
		if(skip) continue;
		res ~= fields[i].name;
	}
	return res;
}

template SelectList(char[] n) {
	const char[] SelectList = "static if(T.length > " ~ n ~ ") {"
		"fields = ReflectionOf!(T[" ~ n ~ "]).fields;"
		"foreach(f; fields) {"
			"res ~= \"'\" ~ T[" ~ n ~ "].stringof ~ \"'.'\" ~ f.name ~ \"',\";"
		"}"
	"}";
}

char[] createJoinSelectList(T...)()
{
	char[] res;
	sendero.util.FieldInfo.FieldInfo[] fields;
	
	/+static if(T.length > 0) {
		fields = ReflectionOf!(T[0]).fields;
		foreach(f; fields) {
			res ~= "'" ~ T[0].stringof ~ "'.'" ~ f.name ~ "',";
		}
	}+/
	
	mixin(SelectList!("0"));
	mixin(SelectList!("1"));
	mixin(SelectList!("2"));
	mixin(SelectList!("3"));
	mixin(SelectList!("4"));
	mixin(SelectList!("5"));
	mixin(SelectList!("6"));
	mixin(SelectList!("7"));
	static if(T.length > 8) static assert(false);
	
	return res[0 .. $ - 1];
}
	
unittest
{
	static class Test
	{
		int a;
		double b;
		char[] c;
	}
	
	static class Test2
	{
		uint y;
		void[] z;
	}
	
	auto select = createJoinSelectList!(Test, Test2)();
	assert(select == "'Test'.'a','Test'.'b','Test'.'c','Test2'.'y','Test2'.'z'", select);
}