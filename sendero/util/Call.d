module sendero.util.Call;


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
	class Test
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