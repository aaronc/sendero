module sendero.orm.Statement;

import dbi.PreparedStatement;

import tango.core.Traits;

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
}

class Statement
{
	this(StatementContainer container)
	{
		this.inst = container;
	}
	
	StatementContainer inst;
	
	private static void bindArgs(void* argptr, TypeInfo[] arguments, inout void*[] ptrs, inout BindType[] types)
	{
		auto len = arguments.length;
		
		ptrs.length = len;
		types.length = len;
		
		for(uint i = 0; i < len; ++i)
		{
			if(arguments[i] == typeid(byte))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.Byte;
			    argptr += byte.sizeof;
			}
			else if(arguments[i] == typeid(ubyte))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.UByte;
			    argptr += ubyte.sizeof;
			}
			else if(arguments[i] == typeid(short))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.Short;
			    argptr += short.sizeof;
			}
			else if(arguments[i] == typeid(ushort))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.UShort;
			    argptr += ushort.sizeof;
			}
			else if(arguments[i] == typeid(int))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.Int;
			    argptr += int.sizeof;
			}
			else if(arguments[i] == typeid(uint))
			{
			    ptrs[i] = argptr;
			    types[i] = BindType.UInt;
			    argptr += uint.sizeof;
			}
			else if(arguments[i] == typeid(long))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.Long;
			    argptr += long.sizeof;
			}
			else if(arguments[i] == typeid(ulong))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.ULong;
			    argptr += ulong.sizeof;
			}
			else if (arguments[i] == typeid(float))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.Float;
			    argptr += float.sizeof;
			}
			else if (arguments[i] == typeid(double))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.Double;
			    argptr += double.sizeof;
			}
			else if (arguments[i] == typeid(char[]))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.String;
			    argptr += ptrs.sizeof;
			}
			else if (arguments[i] == typeid(ubyte[]) || arguments[i] == typeid(void[]))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.Binary;
			    argptr += ptrs.sizeof;
			}
			else if (arguments[i] == typeid(Time))
			{
				ptrs[i] = argptr;
			    types[i] = BindType.Time;
			    argptr += Time.sizeof;
			}
			else assert(false);
		}
	}
	
	bool execute(...)
	{
		if(!_arguments.length)
			return inst.stmt.execute;
		
		void*[] ptrs;
		BindType[] types;
		
		bindArgs(_argptr, _arguments, ptrs, types);
		
		inst.stmt.setParamTypes(types);
		return inst.stmt.execute(ptrs);
	}
	
	void prefetchAll()
	{
		inst.stmt.prefetchAll;
	}
	
	bool fetch(T...)(out T t)
	{
		void*[T.length] ptrs;
		
		static if(T.length > 0)
			ptrs[0] = &t[0];
		static if(T.length > 1)
			ptrs[1] = &t[1];
		static if(T.length > 2)
			ptrs[2] = &t[2];
		static if(T.length > 3)
			ptrs[3] = &t[3];
		static if(T.length > 4)
			ptrs[4] = &t[4];
		static if(T.length > 5)
			ptrs[5] = &t[5];
		static if(T.length > 6)
			ptrs[6] = &t[6];
		static if(T.length > 7)
			ptrs[7] = &t[7];
		
		if(inst.lastResSignature != T.stringof)
		{
			BindType[] types;			
			types.length = T.length;
			
			uint i = 0;
			foreach(x; t)
			{
				types[i] = getBindType!(typeof(x))();
				++i;
			}
			
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
