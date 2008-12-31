/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.db.DBProvider;

debug import tango.util.log.Log;

import dbi.DBI;

import tango.core.Thread;

import sendero.core.Config;
import sendero.util.ConnectionPool;

class DBConnectionProvider(DatabaseT = Database) : ConnectionPool!(DatabaseT)
{
	this(char[] dbUrl)
	{
		this.dbUrl = dbUrl;
	}
	
	char[] dbUrl;
	
	DatabaseT createNewConnection()
	{
		return getDatabaseForURL(dbUrl);
	}
}

class DefaultDatabasePool : ConnectionPool!(Database)
{
	Database createNewConnection()
	{
		assert(SenderoConfig() !is null);
		assert(SenderoConfig().dbUrl !is null);
		auto db = getDatabaseForURL(SenderoConfig().dbUrl);
		assert(db !is null);
		return db;
	}
}

version(dbi_mysql) {
	import dbi.mysql.Mysql;
	
	class DefaultMysqlPool : ConnectionPool!(Mysql)
	{
		Mysql createNewConnection()
		{
			debug assert(SenderoConfig() !is null);
			auto url = SenderoConfig().dbUrl;
			auto db = cast(Mysql)getDatabaseForURL(url);
			assert(db, "Unable to create database connection or Database type is not Mysql, DB URL: " ~ url);
			return db;
		}
	}
	
}

version(dbi_sqlite) {
	import dbi.sqlite.SqliteDatabase;
	
	class DefaultSqlitePool : ConnectionPool!(SqliteDatabase)
	{
		SqliteDatabase createNewConnection()
		{
			assert(SenderoConfig() !is null);
			auto url = SenderoConfig().dbUrl;
			auto db = cast(SqliteDatabase)getDatabaseForURL(url);
			assert(db, "Unable to create database connection or Database type is not Sqlite, DB URL: " ~ url);
			return db;
		}
	}
}

class DBProvider(PoolT)
{
	alias DBProvider!(PoolT) TypeOfThis;
	
	static this()
	{
		debug Log.lookup(TypeOfThis.stringof ~ "").info("entering static this");
		pool_ = new PoolT;
		providers_ = new ThreadLocal!(PoolT.ConnectionT)(null);
	}
	
	static private PoolT pool_;
	static private ThreadLocal!(PoolT.ConnectionT) providers_;
	
	static PoolT.ConnectionT get()
	{
		assert(providers_ !is null);
		auto conn = providers_.val;
		if(conn is null) {
			assert(pool_ !is null);
			conn = pool_.get;
			assert(conn !is null);
			providers_.val = conn;
		}
		return conn;
	}
	alias get opCall;
	
	static void cleanupThread()
	{
		auto conn = providers_.val;
		if(conn !is null) {
			providers_.val = null;
			pool_.release(conn);
		}
	}
}
/+
alias DBProvider!(DefaultDatabasePool) DefaultDatabaseProvider;
version(dbi_mysql) {
	alias DBProvider!(DefaultMysqlPool) DefaultMysqlProvider;	
}

version(dbi_mysql) {
	alias DBProvider!(DefaultSqlitePool) DefaultSqliteProvider;	
}+/