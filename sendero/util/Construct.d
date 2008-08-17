module sendero.util.Construct;

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