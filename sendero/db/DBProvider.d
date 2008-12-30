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

class DBConnectionProvider(DatabaseT = Database) : ConnectionPool!(Database)
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
		return getDatabaseForURL(SenderoConfig().dbUrl);
	}
}

version(dbi_mysql) {
	import dbi.mysql.MysqlDatabase;
	
	class DefaultMysqlPool : ConnectionPool!(MysqlDatabase)
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

class DBProvider(DatabaseT = Database)
{
	alias DBProvider!(DatabaseT) TypeOfThis;
	
	this(ConnectionPool!(DatabaseT) pool)
	{
		debug Log.lookup(TypeOfThis.stringof ~ "").info("entering static this");
		pool_ = pool
		providers_ = new ThreadLocal!(DatabaseT)(null);
	}
	
	private ConnectionPool!(DatabaseT) pool_;
	private ThreadLocal!(DatabaseT) providers_;
	
	DatabaseT get()
	{
		debug assert(providers_);
		auto conn = providers_.val;
		if(conn is null) {
			conn = pool_.get;
			debug assert(conn);
			providers_.val = conn;
		}
		return conn;
	}
	
	void cleanupThread()
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