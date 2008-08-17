/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.db.Statement;

import dbi.Statement;

import tango.core.Traits;

public import sendero.util.Reflection;
public import sendero.db.SqlGen;
import sendero.db.Bind;

debug import tango.io.Stdout;

class StatementContainer
{
	static StatementContainer opCall(IStatement stmt)
	{
		auto cntr = new StatementContainer;
		cntr.stmt = stmt;
		return cntr;
	}
	
	private IStatement stmt;
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

/**
 * Wrapper class for a database prepared statement.
 * 
 */
class Statement
{
	this(StatementContainer container)
	{
		this.inst = container;
	}
	
	private StatementContainer inst;
	
	/**
	 * Returns the underlying DBI IPreparedStatement instance.
	 */
	IStatement statement()
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
					"t[" ~ n ~ "] = new typeof(t[" ~ n ~ "]);"
					"ptrs ~= bindClassStruct(t[" ~ n ~ "]);"
				"}"
				"else "
					"ptrs ~= &t[" ~ n ~ "];"
			"}";
	}
	
	static void*[] setPtrs(T...)(ref T t)
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
		
		foreach(Index, Type; T)
		{
			static if (is(Type == BindInfo))
				ptrs ~= info.ptrs;
			static if(is(Type == class) || is(Type == struct)) {
				t[Index] = new Type;
				ptrs ~= bindClassStruct(t[Index]);
			}
			else ptrs ~= &t[Index];
		}
		
		/+mixin(SetPtrs!("0"));
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
		mixin(SetPtrs!("15"));+/
		
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
	
	void execute(T...)(T t)
	{
		static if(T.length) {
			void*[] ptrs = setPtrs(t);
			
			bool changed = false; 
			
			if(inst.lastParamSignature.length < T.stringof.length ||
				inst.lastParamSignature[0 .. T.stringof.length] != cast(ubyte[])T.stringof)
				changed = true;
			
			if(!changed) {
				size_t i = T.stringof.length;
				
				foreach(Index, Type; T)
				{
					static if(is(Type == BindInfo)) {
						if(inst.lastParamSignature.length < t[Index].types.length + i ||				
							inst.lastParamSignature[i .. i + t[Index].types.length] != t[Index].types)
						{
							changed = true;
							break;
						}
						i += t[Index].types.length;
					}
				}
			}
			
			/+
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
			mixin(CheckBindInfo!("15"));+/
			
			if(changed)
			{
				BindType[] types = setBindTypes(t);
				inst.stmt.setParamTypes(types);
				
				//debug Stdout.formatln("Param Types {}", types);
				
				ubyte[] signature = cast(ubyte[])T.stringof;
				foreach(Index, Type; T)
				{
					static if(T.length > Index && is(Type == BindInfo)) {
						signature ~= t[Index].types;
					}
				}
				inst.lastParamSignature = signature;
			}
			
			inst.stmt.execute(ptrs);
		}
		else {
			inst.stmt.execute;
		}
	}
	
	void executeEmpty()
	{
		inst.stmt.execute;
	}
	
	bool fetch(T...)(out T t)
	{
		void*[] ptrs = setPtrs(t);
		
		ubyte[] signature = cast(ubyte[])T.stringof;
		
		foreach(Index, Type; T)
		{
			static if(T.length > Index && is(Type == BindInfo)) {
				signature ~= t[Index].types;
			}
		}
		
		/+mixin(CheckBindInfo!("0"));
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
		mixin(CheckBindInfo!("15"));+/
		
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