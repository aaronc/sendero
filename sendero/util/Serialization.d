/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.Serialization;

import tango.io.protocol.Writer, tango.io.protocol.Reader;
import tango.io.protocol.model.IProtocol;
import tango.io.protocol.EndianProtocol;
import tango.io.Conduit, tango.io.Buffer;
import tango.io.FileConduit;
import tango.core.Traits;

bool loadFromFile(T)(inout T t, char[] filename)
{

	FileConduit.Style style;
	style.access = FileConduit.Access.Read;
	style.open = FileConduit.Open.Exists;
	style.share = FileConduit.Share.Read;
	auto infile = new FileConduit(filename, style);
	if(!infile)
		return false;
	
	auto deserializer = new SimpleBinaryInArchiver(infile);
	deserializer (t);
	
	infile.close;
	
	return true;
}

bool saveToFile(T)(T t, char[] filename)
{
	auto outfile = new FileConduit(filename, FileConduit.WriteCreate);
	if(!outfile)
		return false;
	
	auto serializer = new SimpleBinaryOutArchiver(outfile);
	serializer (t);
	
	serializer.flush;
	outfile.flush;
	outfile.close;
	
	return true;
}



interface IHandler
{
	Object construct();
	void handle(Object o, SimpleBinaryInArchiver ar, byte ver);
	void handle(Object o, SimpleBinaryOutArchiver ar, byte ver);
}

/**
 *  
 * Each class that is to be serialized should define the following templated public method:
 * 
 * ---
 * void serialize(Ar)(Ar ar, byte ver)
 * {
 * 	ar (a) (b) (c);
 * }
 * ---
 * 
 * where a, b, and c are data members to be serialized.
 * 
 * Serialization of polymorphic classes and interfaces:
 * Each polymorphic class that is to be serialized should register itself in its static constructor
 * as follows:
 * 
 * ---
 * static this()
 * {
 * 	Serialization.register!(T)();
 * }
 * ---
 * 
 * Where T is the identifier of the class.
 * 
 * The following method should also be defined for each class in the class hierarchy and should return
 * a unique string representing this class (the .mangleof property is a good choice for this value):
 * 
 * ---
 * char[] classid();
 * ---
 * 
 * The serialization method will then need to call the parent class's serialization method.
 * ---
 * void serialize(Ar)(Ar ar, byte ver)
 * {
 * 	super.serialize(ar, ver);
 * }
 * ---
 *  
 * 
 */

class Serialization
{
	static void register(T)()
	{
		scope t = new T;
		auto name = t.classid;
		handlers[name] = new Handler!(T);
	}
	
	static Object construct(char[] name)
	{
		auto ctr = name in handlers;
		if(!ctr) return null;
		return (*ctr).construct;
	}
	
	private static class Handler(T) : IHandler
	{
		Object construct() { return new T;}
		
		void handle(Object o, SimpleBinaryOutArchiver ar, byte ver)
		{
			h (o, ar, ver);
		}
		
		void handle(Object o, SimpleBinaryInArchiver ar, byte ver)
		{
			h (o, ar, ver);
		}
		
		void h(Ar)(Object o, Ar ar, byte ver)
		{
			T t = cast(T)o;
			t.serialize(ar, ver);
		}
	}
	
	private static IHandler[char[]] handlers;
}

template isHandledType(T)
{
	const bool isHandledType = 	isIntegerType!(T) || 
								isRealType!(T) || 
								isCharType!(T) || 
								is(T == bool);
}

template isWritableAndReadable(T)
{
	const bool isWritableAndReadable = is(T:IWritable) && is(T:IReadable);
}

class ArchiveException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}

class SerializationException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}

class SimpleBinaryOutArchiver
{
	alias put opCall;
	
	this(IProtocol protocol)
	{
		writer = new Writer(protocol);
		init;
	}
	
	this(OutputStream stream)
	{
		writer = new Writer(stream);
		init;
	}
	
	this(IWriter writer)
	{
		this.writer = writer;
		init;
	}
	
	private void init()
	{
		version(LittleEndian)
		{
			ubyte endianMarker = 0;
			writer(endianMarker);
		}
		version(BigEndian)
		{
			ubyte endianMarker = 1;
			writer(endianMarker);
		}
		ubyte versionMarker = 0;
		writer(versionMarker);
	}
	
	private IWriter writer;
	
	private uint[void*] ptrs;

	ushort[char[]] registeredClasses;
	
	SimpleBinaryOutArchiver put(T)(T t, char[] name = null)
	{
		static if(isHandledType!(T))
		{
			writer (t);
		}
		else static if(is(T == class) || ( is(T == interface) && is(typeof(T.classid)) ) )
		{
			uint* ptrIdx = (cast(void*)t in ptrs);
			if(ptrIdx) {
				byte tag = -1;
				writer(tag);
				writer(*ptrIdx);
				return this;
			}
			
			static if(is(typeof(t.classid)))
			{
				byte v = 0;
				static if(is(typeof(t.classVersion)))
				{
					v = t.classVersion;
				}
				
				auto clsName = t.classid;
				auto pID = (clsName in registeredClasses);
				if(pID) {
					byte tag = -3;
					writer(tag);
					writer(*pID);
				}
				else {
					byte tag = -2;
					writer(tag);
					writer(clsName);
					writer(v);
					
					ushort id = registeredClasses.length;
					registeredClasses[clsName] = id;
				}
				uint i = ptrs.length;
				ptrs[cast(void*)t] = i;
			
				auto handler = (clsName in Serialization.handlers);
				if(!handler) throw new SerializationException("Derived class " ~ clsName ~ " not registered via Serialization.register(T)()");
				(*handler).handle(t, this, v);				
			}
			else
			{	
				byte v = 0;
				static if(is(typeof(t.classVersion)))
				{
					v = t.classVersion;
				}
				writer(v);
				
				uint i = ptrs.length;
				ptrs[cast(void*)t] = i;
				t.serialize(this, v);
			}
		}
		else static if(is(T == struct))
		{
			byte v = 0;
			static if(is(typeof(t.classVersion)))
			{
				v = t.classVersion;
			}
			
			writer(v);
			
			t.serialize(this, v);
		}
		else static if(isAssocArrayType!(T))
		{
			uint len = t.length;
			writer(len);
			foreach(k, v; t)
			{
				put (k);
				put (v);
			}
		}
		else static if(isDynamicArrayType!(T))
		{
			static if(isHandledType!(typeof(T.init[0])))
			{
				writer(t);
			}
			else
			{
				uint len = t.length;
				
				writer(len);
				foreach(x; t)
				{
					put(x);
				}
			}
		}
		else static if(isComplexType!(T))
		{
			writer (t.re) (t.im);
		}
		else static if(isPointerType!(T))
		{
			static if(is(T == class) || is(T == interface))
			{
				assert(false, "Serialization of class pointers not supported in this version, type " ~ T.stringof ~ "*");
				//put (*t);
				//return this;
			}
			
			uint* ptrIdx = (cast(void*)t in ptrs);
			if(ptrIdx) {
				byte tag = -1;
				writer(tag);
				writer(*ptrIdx);
				return this;
			}
			
			byte tag = 0;
			writer(tag);
			put(*t);
			
			uint i = ptrs.length;
			ptrs[cast(void*)t] = i;
		}
		else assert(false, "Unhandled serialization type " ~ T.stringof);
		
		return this;
	}
	
	bool loading() {return false;}
	
	void flush()
	{
		writer.flush;
	}
}

class SimpleBinaryInArchiver
{
	alias get opCall;
	
	private IReader reader;
	
	version(LittleEndian)
	{
		const ubyte oppositeEndiannessMarker = 1;
	}
	version(BigEndian)
	{
		const ubyte oppositeEndiannessMarker = 0;
	}

    this (IProtocol protocol)
    {
    	reader = new Reader(protocol);
    	ubyte endianMarker;
    	reader(endianMarker);
    	
		if(endianMarker == oppositeEndiannessMarker)
		{
			auto endian = new EndianProtocol(protocol.buffer);
			reader = new Reader(endian);
		}
		
		init;
    }
    
    this (InputStream inputStream)
    {
    	reader = new Reader(inputStream);
		ubyte endianMarker;
    	reader(endianMarker);
		
		if(endianMarker == oppositeEndiannessMarker)
		{
			void[] data;
			auto buffer = cast(IBuffer) inputStream;
			if(!buffer) {
				uint len = inputStream.read(data);
				buffer = new Buffer(data);
			}
			auto endian = new EndianProtocol(buffer);
			reader = new Reader(endian);
		}
		
		init;
    }
    
    private ubyte versionMarker;
    private void init()
    {
		reader(versionMarker);
    }
    
    private void*[] ptrs;
    private static struct ClassRegistration
    {
    	char[] name;
    	byte ver;
    }
    private ClassRegistration[ushort] registeredClasses;
    
    void getPtr(T)(inout T* t)
    {
    	static if(is(T == class) || is(T == interface))
		{
    		assert(false, "Serialization of class pointers not supported in this version, type " ~ T.stringof ~ "*");
    	/*	T x;
    		get (x);
    		t = cast(T*)x;
    		return;*/
		}
    	
    	byte tag;
		reader(tag);
		if(tag == -1) {
			uint ptrIdx;
			reader(ptrIdx);
			if(ptrIdx >= ptrs.length) t = null;
			else t = cast(T*)ptrs[ptrIdx];
			return;	
		}
		
    	t = new T;
		get (*t);
		ptrs ~= cast(void*) t;
    }
	
	SimpleBinaryInArchiver get(T)(inout T t, char[] name = null)
	{
		static if(isHandledType!(T))
		{
			reader(t);
		}
		else static if(is(T == class) || ( is(T == interface) && is(typeof(T.classid)) ) )
		{
			byte tag, v;
			reader(tag);
			if(tag == -1) {
				uint ptrIdx;
				reader(ptrIdx);
				if(ptrIdx >= ptrs.length) t = null;
				else t = cast(T)ptrs[ptrIdx];
				return this;	
			}
			
			static if(is(typeof(t.classid)))
			{
				char[] clsName;
				
				SimpleBinaryInArchiver handle()
				{
					auto handler = (clsName in Serialization.handlers);
					if(!handler) throw new ArchiveException("Derived class " ~ clsName ~ " not registered via Serialization.register(T)()");
					t = cast(T)(*handler).construct;
					(*handler).handle(t, this, v);
					ptrs ~= cast(void*) t;
					return this;
				}
				
				if(tag == -2) {
					reader(clsName);
					reader(v);
					
					ushort id = registeredClasses.length;
									
					ClassRegistration reg;
					reg.name = clsName;
					reg.ver = v;
					
					registeredClasses[id] = reg;
					
					return handle;
				}
				else if(tag == -3) {
					ushort id;
					reader(id);
					auto reg = (id in registeredClasses);
					if(!reg) throw new ArchiveException("Referenced class not registered in archive");
					clsName = (*reg).name;
					v = (*reg).ver;
					
					return handle;
				}
				else {
					v = tag;
				}
			}
			
			t = new T;
			ptrs ~= cast(void*) t;
			t.serialize(this, v);
			return this;
		}
		else static if(is(T == struct))
		{
			byte v;
			reader (v);
			t.serialize(this, v);
		}
		else static if(isAssocArrayType!(T))
		{
			uint len;
			reader (len);
			
			for(uint i = 0; i < len; ++i)
			{
				typeof(t.keys[0]) k;
				get (k);
				typeof(t.values[0]) v;
				get (v);
				t[k] = v;
			}
		}
		else static if(isDynamicArrayType!(T))
		{
			static if(isHandledType!(typeof(T.init[0])))
			{
				reader(t);
			}
			else
			{
				uint len;
				reader(len);
				
				t.length = len;
				for(uint i = 0; i < len; ++i)
				{
					get(t[i]);
				}
			}
		}
		else static if(isComplexType!(T))
		{
			reader (t.re) (t.im);
		}
		else static if(isPointerType!(T))
		{	
			getPtr(t);
		}
		else assert(false, "Unhandled serialization type " ~ T.stringof);
		
		return this;
	}
	
	bool loading() {return true;}
}

version(Unittest)
{
	import tango.io.Buffer;
	
	class TestA
	{
		ubyte a;
		uint b;
		int c;
		double d;
		char[] e;
		TestB f;
		char[][char[]] g;
		TestB[] h;
		TestB i;
		int[] j;
		int* k;
		
		void serialize(Ar)(Ar ar, byte ver)
		{
			ar (a) (b) (c) (d) (e) (f) (g) (h) (i) (j) (k);
		}
	}
	
	class TestB
	{
		static this()
		{
			Serialization.register!(TestB)();
		}
		
		float x;
		
		char[] classid() {return this.mangleof;}
		
		void serialize(Ar)(Ar ar, byte ver)
		{
			ar (x);
		}
	}
	
	class TestC : TestB
	{
		static this()
		{
			Serialization.register!(TestC)();
		}
		
		char[] classid() {return this.mangleof;}
		
		double z;
		
		void serialize(Ar)(Ar ar, byte ver)
		{
			super.serialize(ar, ver);
			ar (z);
		}
	}

unittest
{
	auto a = new TestA;
	a.a = 5;
	a.b = 7;
	a.c = -14;
	a.d = 3.14159;
	a.e = "hello world";

	a.f = new TestB;
	a.f.x = 7.379;
	
	a.g["hello"] = "world";
	a.h.length = 1;
	a.h[0] = a.f;
	a.i = a.f;
	a.j.length = 2;
	a.j[0] = 5;
	a.j[1] = 6;
	
	a.k = new int;
	*(a.k) = 4;
	
	auto buf = new Buffer(256);
	auto sboa = new SimpleBinaryOutArchiver(buf);
	sboa (a);
	
	auto sbia = new SimpleBinaryInArchiver(buf);
	TestA aCopy;
	sbia (aCopy);
	
	assert(a.a == aCopy.a);
	assert(a.b == aCopy.b);
	assert(a.c == aCopy.c);
	assert(a.d == aCopy.d);
	assert(a.e == aCopy.e);
	assert(a.f.x == aCopy.f.x);
	assert(a.g["hello"] == aCopy.g["hello"]);
	assert(aCopy.h.length == 1);
	assert(aCopy.h[0]);
	assert(aCopy.f.x == aCopy.h[0].x);
	assert(aCopy.f == aCopy.h[0]);
	assert(cast(void*)aCopy.f == cast(void*)aCopy.i);
	assert(a.j[0] == aCopy.j[0]);
	assert(a.j[1] == aCopy.j[1]);
	assert(*(a.k) == *(aCopy.k));
	
	auto c = new TestC;
	TestB b = c;
	c.x = 3.4197;
	c.z = 4.7684;
	
	auto buf2 = new Buffer(256);
	
	sboa = new SimpleBinaryOutArchiver(buf2);
	sboa (b);
	
	sbia = new SimpleBinaryInArchiver(buf2);
	TestB bCopy;
	sbia(bCopy);
	
	TestC cCopy = cast(TestC)bCopy;
	
	assert(cCopy.x == c.x);
	assert(cCopy.z == c.z);
}

}