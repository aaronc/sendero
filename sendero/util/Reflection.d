module sendero.util.Reflection;

class FieldInfo
{
	char[] name;
	size_t offset;
	ubyte ordinal;
}

template Reflector(char[] i)
{	
	const char[] Reflector =  "static if(T.tupleof.length > " ~ i ~ ") { i = new FieldInfo; i.offset = T.tupleof[" ~ i ~ "].offsetof; "
			"i.name = T.tupleof[" ~ i ~ "].stringof[classname.length + 3 .. $];"
			"i.ordinal = n;"
			"info ~= i;"
			"++n;"
			"}";
}

template VisitTuple() {
	const char[] VisitTuple = "uint i = 0;"
							"foreach(x; t.tupleof)"
							"{"
								"v.visit!(typeof(x))(x, i);"
								"++i;"
							"}";
}

class ReflectionOf(T) {
	static this()
	{
		static if(is(typeof(T.reflect)))
		{
			fields = T.reflect();
		}
		else
		{
			assert(T.tupleof.length <= limit, "Too many fields in class");
			fields = reflect();
		}
	}
	
	const static int limit = 64;
	const static FieldInfo[] fields;
	
	mixin Reflect!(T);
	
	static void visitTuple(Visitor)(T t, Visitor v)
	{
		static if(is(typeof(T.visitTuple)))
		{
			fields = T.reflect();
		}
		else {
			mixin(VisitTuple!());
		}
	}
}

template Expose(T)
{
	mixin Reflect!(T);
	
	static void visitTuple(Visitor)(T t, Visitor v)
	{
		mixin(VisitTuple!());
	}
}

template Reflect(T)
{
	static FieldInfo[] reflect()
	{
		char[] classname = T.stringof;
		FieldInfo[] info;
		
		uint n = 0;
		FieldInfo i;
		
		mixin(Reflector!("0"));
		mixin(Reflector!("1"));
		mixin(Reflector!("2"));
		mixin(Reflector!("3"));
		mixin(Reflector!("4"));
		mixin(Reflector!("5"));
		mixin(Reflector!("6"));
		mixin(Reflector!("7"));
		mixin(Reflector!("8"));
		mixin(Reflector!("9"));
		mixin(Reflector!("10"));
		mixin(Reflector!("11"));
		mixin(Reflector!("12"));
		mixin(Reflector!("13"));
		mixin(Reflector!("14"));
		mixin(Reflector!("15"));
		mixin(Reflector!("16"));
		mixin(Reflector!("17"));
		mixin(Reflector!("18"));
		mixin(Reflector!("19"));
		mixin(Reflector!("20"));
		mixin(Reflector!("21"));
		mixin(Reflector!("22"));
		mixin(Reflector!("23"));
		mixin(Reflector!("24"));
		mixin(Reflector!("25"));
		mixin(Reflector!("26"));
		mixin(Reflector!("27"));
		mixin(Reflector!("28"));
		mixin(Reflector!("29"));
		mixin(Reflector!("30"));
		mixin(Reflector!("31"));
		mixin(Reflector!("32"));
		mixin(Reflector!("33"));
		mixin(Reflector!("34"));
		mixin(Reflector!("35"));
		mixin(Reflector!("36"));
		mixin(Reflector!("37"));
		mixin(Reflector!("38"));
		mixin(Reflector!("39"));
		mixin(Reflector!("40"));
		mixin(Reflector!("41"));
		mixin(Reflector!("42"));
		mixin(Reflector!("43"));
		mixin(Reflector!("44"));
		mixin(Reflector!("45"));
		mixin(Reflector!("46"));
		mixin(Reflector!("47"));
		mixin(Reflector!("48"));
		mixin(Reflector!("49"));
		mixin(Reflector!("50"));
		mixin(Reflector!("51"));
		mixin(Reflector!("52"));
		mixin(Reflector!("53"));
		mixin(Reflector!("54"));
		mixin(Reflector!("55"));
		mixin(Reflector!("56"));
		mixin(Reflector!("57"));
		mixin(Reflector!("58"));
		mixin(Reflector!("59"));
		mixin(Reflector!("60"));
		mixin(Reflector!("61"));
		mixin(Reflector!("62"));
		mixin(Reflector!("63"));
		return info;
	}
}

version(Unittest)
{
	static class A
	{
		int x;
		uint y;
		char[] c;
	}
	
	static class B
	{
		private int x;
		private uint y;
		private char[] c;
		mixin Expose!(B);
	}
	
	static class TestVisitor
	{
		char[][] names;
				
		void visit(X)(X x, uint index)
		{
			names ~= X.stringof;
		}
	}
}

unittest
{
	assert(ReflectionOf!(A).fields[0].name == "x", ReflectionOf!(A).fields[0].name);
	assert(ReflectionOf!(A).fields[1].name == "y", ReflectionOf!(A).fields[1].name);
	assert(ReflectionOf!(A).fields[2].name == "c", ReflectionOf!(A).fields[2].name);
	
	auto testVisitorA = new TestVisitor;
	auto a = new A;
	ReflectionOf!(A).visitTuple(a, testVisitorA);
	assert(testVisitorA.names[0] == "int", testVisitorA.names[0]);
	assert(testVisitorA.names[1] == "uint", testVisitorA.names[1]);
	assert(testVisitorA.names[2] == "char[]", testVisitorA.names[2]);
	
	assert(ReflectionOf!(B).fields[0].name == "x", ReflectionOf!(B).fields[0].name);
	assert(ReflectionOf!(B).fields[1].name == "y", ReflectionOf!(B).fields[1].name);
	assert(ReflectionOf!(B).fields[2].name == "c", ReflectionOf!(B).fields[2].name);
	
	auto testVisitorB = new TestVisitor;
	auto b = new B;
	ReflectionOf!(B).visitTuple(b, testVisitorB);
	assert(testVisitorB.names[0] == "int", testVisitorB.names[0]);
	assert(testVisitorB.names[1] == "uint", testVisitorB.names[1]);
	assert(testVisitorB.names[2] == "char[]", testVisitorB.names[2]);	
}