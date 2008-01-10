module sendero.orm.Statement;

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
	private char[] lastResSignature;
	private char[] lastParamSignature;
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
	
	StatementContainer inst;
	
	void prefetchAll()
	{
		inst.stmt.prefetchAll;
	}
	
	static BindType[] getClassStructTypes(T)()
	{
		auto visitor = new TypeVisitor;
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
			static if(is(typeof(x) == class) || is(typeof(x) == struct))
				types ~= getClassStructTypes!(typeof(x))();
			else
				types ~= getBindType!(typeof(x))();
		}
		
		return types;
	}
	
	bool execute(T...)(T t)
	{
		static if(T.length) {
			void*[] ptrs = setPtrs(t);
			
			if(inst.lastParamSignature != T.stringof)
			{
				BindType[] types = setBindTypes(t);
				
				inst.stmt.setParamTypes(types);
				inst.lastParamSignature = T.stringof;
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
		
		if(inst.lastResSignature != T.stringof)
		{
			BindType[] types = setBindTypes(t);
			
			inst.stmt.setResultTypes(types);
			inst.lastResSignature = T.stringof;
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

template SelectList(char[] n) {
	const char[] SelectList = "static if(T.length > " ~ n ~ ") {"
		"fields = ReflectionOf!(T[" ~ n ~ "]).fields;"
		"foreach(f; fields) {"
			"res ~= \"'\" ~ T[" ~ n ~ "].stringof ~ \"'.'\" ~ f.name ~ \"',\";"
		"}"
	"}";
}

char[] createSelectList(T...)()
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

/+char[] createUpdate(T...)(char[] where = null)
{
	char[] res = "UPDATE " ~ T.stringof ~ " SET ";
	static if(T.length > 0) {
		auto fields = ReflectionOf!(T[0]).fields;
		foreach(f; fields)
		{
			res ~= "'" ~ T[0].stringof ~ "'.'" ~ f.name ~ "' = ?,";
		}
	}
	
	res = res[0 .. $ - 1];
	
	if(where) res ~= " " ~ where;
	
	return res;
}+/
	
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
	
	auto select = createSelectList!(Test, Test2)();
	assert(select == "'Test'.'a','Test'.'b','Test'.'c','Test2'.'y','Test2'.'z'", select);
}