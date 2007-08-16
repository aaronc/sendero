module sendero.data.test.Tests;

version(Unittest)
{
	public import sendero.data.DB;
	public import sendero.data.Associations;
	import tango.util.log.Log;
	import tango.util.log.FileAppender;
	import tango.util.log.DateLayout;
	
	class A
	{
		PrimaryKey id;
		void[] blob;
		char[] txt;
		DateTime dateTime;
	}
	
	class B
	{
		PrimaryKey id;
		double d;
		int x;
		bool yes;
		HasOne!(A) a;
	}
	
	class UsersGroups : JoinTable!(User, Group)
	{
		int x;
	}
	
	class User
	{
		HABTM!(Group, UsersGroups) groups;
		char[] username;
		void[] password_hash;
		PrimaryKey id;
	}
	
	class Group
	{
		PrimaryKey id;
		char[] name;
		HABTM!(User, UsersGroups) users;
	}
	
	void runTests(DBConnection)(DBConnection db)
	{
		char[] dbStr = DBConnection.stringof;
		auto appender = new FileAppender(dbStr ~ "_test.log");
		Log.getRootLogger.addAppender(appender);
		
		assert(db, dbStr);
		
		auto aSer = new DBSerializer!(A)(db);
		assert(aSer, dbStr);
		
		auto bSer = new DBSerializer!(B)(db);
		assert(bSer, dbStr);
		
		auto a = new A;
		a.blob = r"sdgh*&Y#*(";
		a.txt = "Hello World!";
		assert(aSer.save(a), dbStr);
		assert(a.id(), dbStr);
		
		auto aCopy = aSer.findByID(a.id());
		assert(aCopy, dbStr);
		assert(aCopy.blob == a.blob, dbStr);
		assert(aCopy.txt == a.txt, dbStr ~ ":" ~ aCopy.txt);
		
		auto b = new B;
		b.a = a;
		assert(bSer.save(b), dbStr);
		auto bCopy = bSer.findByID(b.id());
		assert(bCopy, dbStr);
		assert(bCopy.a.get.id() == a.id(), dbStr);
		assert(bCopy.a.get, dbStr);
		assert(bCopy.a.get.blob == a.blob, dbStr);
		assert(bCopy.a.get.txt == a.txt, dbStr);
		
		auto u = new User;
		u.username = "bob";
		auto g = new Group;
		g.name = "Volleyball Enthusiasts";
		
		auto userSer = new DBSerializer!(User)(db);
		auto groupSer = new DBSerializer!(Group)(db);
		
		groupSer.save(g);
		u.groups ~= g;
		userSer.save(u);
		
		auto gCopy = groupSer.findByID(g.id());
		assert(gCopy, dbStr);
		assert(gCopy.users.get, dbStr);
		assert(gCopy.users.get.length == 1, dbStr);
		assert(gCopy.users.get[0].val.username == "bob", dbStr);
		
		auto uCopy = userSer.findByID(u.id());
		assert(uCopy, dbStr);
		assert(uCopy.username == "bob", dbStr);
		assert(uCopy.groups.get, dbStr);
		assert(uCopy.groups.get.length == 1, dbStr);
		assert(uCopy.groups.get[0].val.name == "Volleyball Enthusiasts", dbStr);
		
		scope(exit) appender.close;
	}
}