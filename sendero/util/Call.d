module sendero.util.Call;

struct Construct(T, Params...)
{
	static void register(T function(Params) constructor)
	{ create_ = constructor; }
	static T function(Params) create_;
	
	static debug T create(Params params)
	{
		assert(create_);
		return create_(params);
	}
	else alias create_ create;
}

debug(SenderoUnittest)
{
	class Test
	{
		static this()
		{
			Construct!(Test).register(&create);
		}
		
		static Test create()
		{
			return new Test;
		}
	}
	
	unittest
	{
		auto t = Construct!(Test).create;
		assert(t ! is null);
		assert(is(typeof(t) == Test));
	}
}

struct Call(char[] methodName, ResT, Params...)
{
	static void register(ResT function(Params) constructor)
	{ call_ = constructor; }
	static ResT function(Params) call_;
	
	static debug ResT call(Params params)
	{
		assert(call_);
		return call_(params);
	}
	else alias call_ call;
}

debug(SenderoUnittest)
{
	class Test2
	{
		static this()
		{
			Call!("echo", char[], char[]).register(&echo);
		}
		
		static char[] echo(char[] val)
		{
			return val;
		}
	}
	
	unittest
	{
		auto res = Call!("echo", char[], char[]).call("test");
		assert(res == "test");
	}
}