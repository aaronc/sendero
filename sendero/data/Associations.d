module sendero.data.Associations;

import sendero.data.DB;

struct HasOne(T)
{
	package DBSerializer!(T) db;
	private T t;
	alias T type;
	package ulong id = 0;
	
	void opAssign(T t)
	{
		this.t = t;
		this.id = t.id();
	}
	
	T get()
	{
		if(t) {
			return t;
		}
		if(id && db) {
			t = db.findByID(id);
			return t;
		}
		return null;
	}
}



version(Unittest)
{
	class A
	{
		PrimaryKey id;
		uint x;
	}
	
	class B
	{
		PrimaryKey id;
		HasOne!(A) a;
	}
}

unittest
{
	assert(TableDescriptionOf!(B).columns[1].type == ColT.HasOne);
}