module sendero.db.Relations;

struct HasOne(Type, UInt = uint)
{	
	UInt id;
	Type inst;
}

/+struct HasOne(T, UInt = uint)
{
	BindInfo[] save()
	{
		if(t_) {
			return BindInfo([BindType.UInt], [&t_.id]);
		}
		else return BindInfo([BindType.Null], [null]);
	}
	
	BindInfo[] retrieve(bool get = false)
	{
		
	}
	
	private UInt id_;
	private T t_;
	
	void opAssign(T t)
	{
		t_ = t;
	}
	
	T get()
	{
		if(t_) return t_;
		else if(id_) {
			t_ = T.getByID(id_);
			return t_;
		}
		else return null;
	}
}+/

debug(SenderoUnittest)
{	
	unittest
	{
		
	}
}
