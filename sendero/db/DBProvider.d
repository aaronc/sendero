/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.db.DBProvider;

debug import tango.util.log.Log;

import dbi.all;
import tango.core.Thread;
import sendero.util.ConnectionPool;

import sendero.core.Config;

public import sendero.db.Statement;

class DBConnectionProvider(char[] dbUrl, DatabaseT = Database)
{
	static Database createNewConnection()
	{
		return getDatabaseForURL(dbUrl);
	}
}

class DefaultConnectionProvider
{
	static Database createNewConnection()
	{
		return getDatabaseForURL(SenderoConfig().dbUrl);
	}
}

version(dbi_mysql) {
	import dbi.mysql.MysqlDatabase;
	
	class DefaultMysqlConnectionProvider
	{
		static MysqlDatabase createNewConnection()
		{
			debug assert(SenderoConfig() !is null);
			auto url = SenderoConfig().dbUrl;
			auto db = cast(MysqlDatabase)getDatabaseForURL(url);
			assert(db, "Unable to create database connection or Database type is not Mysql, DB URL: " ~ url);
			return db;
		}
	}
	
}

version(dbi_sqlite) {
	import dbi.sqlite.SqliteDatabase;
	
	class DefaultSqliteConnectionProvider
	{
		static SqliteDatabase createNewConnection()
		{
			assert(SenderoConfig() !is null);
			auto url = SenderoConfig().dbUrl;
			auto db = cast(SqliteDatabase)getDatabaseForURL(url);
			assert(db, "Unable to create database connection or Database type is not Sqlite, DB URL: " ~ url);
			return db;
		}
	}
}


interface IProvider(StatementT, ConnectionT)
{
	bool prepare(char[] statement, inout StatementT stmt, char[] key = null);
	bool prepareRaw(char[] statement, inout IStatement stmt, char[] key = null);
	bool virtualPrepare(char[] statement, inout StatementT stmt);
	bool virtualPrepareRaw(char[] statement, inout IStatement stmt);
	void beginTransact();
	void rollback();
	void commit();
	SqlGenerator sqlGen();
	ConnectionT getInstance();
}

class ProviderContainer(ConnectionT, ProviderT, StatementT) : IProvider!(StatementT, ConnectionT)
{
	this(ConnectionT inst)
	{
		this.inst = inst;
	}
	
	bool prepare(char[] statement, inout StatementT stmt, char[] key = null)
	{
		StatementT* pStmt = null;
		if(key.length) pStmt = key in cachedStatements;
		else pStmt = statement in cachedStatements;
		
		if(pStmt) {
			stmt = *pStmt;
			return true;
		}
		
		auto rawStmt = inst.prepare(statement);
		if(!rawStmt)
			return false;
		
		stmt = StatementT(rawStmt);
		//debug assert(stmt);
		if(key.length) cachedStatements[key] = stmt;
		else cachedStatements[statement] = stmt;
		return true;
	}
	
	bool virtualPrepare(char[] statement, inout StatementT stmt)
	{
		auto rawStmt = inst.virtualPrepare(statement);
		if(!rawStmt)
			return false;
		
		stmt = StatementT(rawStmt);
		return true;
	}
	
	bool prepareRaw(char[] statement, inout IStatement stmt, char[] key = null)
	{
		IStatement* pStmt = null;
		if(key.length) pStmt = key in cachedRawStatements;
		else pStmt = statement in cachedRawStatements;
		if(pStmt) {
			stmt = *pStmt;
			return true;
		}
		
		auto rawStmt = inst.prepare(statement);
		if(!rawStmt)
			return false;
		
		stmt = rawStmt;
		if(key.length) cachedRawStatements[key] = stmt;
		else cachedRawStatements[statement] = stmt;
		return true;
	}
	
	bool virtualPrepareRaw(char[] statement, inout IStatement stmt)
	{
		stmt = inst.virtualPrepare(statement);
		if(!stmt) return false;
		else return true;
	}
	
	void beginTransact()
	{
		inst.beginTransact;
	}
	
	void rollback()
	{
		inst.rollback;
	}
	
	void commit()
	{
		inst.commit;
	}
	
	SqlGenerator sqlGen()
	{
		return inst.sqlGen;
	}
	
	ConnectionT getInstance()
	{
		return inst;
	}
	
	private ConnectionT inst;
	private StatementT[char[]] cachedStatements;
	private IStatement[char[]] cachedRawStatements;
	
	~this()
	{
		ProviderT.releaseConnection(inst);
	}
}



class DBProvider(DBConnectionProvider, DatabaseT = Database)
{
	static this()
	{
		debug Log.lookup("DBProvider." ~ DBConnectionProvider.stringof ~ "." ~ DatabaseT.stringof ~ "").info("entering static this");
		pool = new ConnectionPool!(DatabaseT, DBConnectionProvider);
		providers_ = new ThreadLocal!(ProviderContainer!(DatabaseT, DBProvider!(DBConnectionProvider, DatabaseT), StatementContainer))(null);
	}
	
	/+static ~this()
	{
		auto conn = pool.getConnection;
		while(conn !is null) {
			conn.close;
			conn = pool.getConnection;
		}
	}+/
	
	private static ConnectionPool!(Database, DBConnectionProvider) pool;
	private static ThreadLocal!(ProviderContainer!(Database, DBProvider!(DBConnectionProvider), StatementContainer)) providers_;
	
	private static IProvider!(StatementContainer, DatabaseT) getProvider()
	{
		debug assert(providers_);
		auto provider = providers_.val;
		if(!provider) {
			auto conn = pool.getConnection;
			debug assert(conn);
			if(!conn) return null;
			provider = new ProviderContainer!(Database, DBProvider!(DBConnectionProvider), StatementContainer)(conn);
			debug assert(provider);
			providers_.val = provider;
		}
		return provider;
	}
	
	static void releaseConnection(Database conn)
	{
		pool.releaseConnection(conn);
	}
		
	static Statement prepare(char[] sql, char[] key = null)
	{
		auto provider = getProvider;
		StatementContainer cntr;
		if(!provider.prepare(sql, cntr, key)) {
			debug throw new Exception("Unable to create statement:" ~ sql);
			else throw new Exception("Unable to create statement");
		}
		
		return new Statement(cntr);
	}
	
	static Statement virtualPrepare(char[] sql, char[] key = null)
	{
		auto provider = getProvider;
		StatementContainer cntr;
		if(!provider.virtualPrepare(sql, cntr)) {
			debug throw new Exception("Unable to create statement:" ~ sql);
			else throw new Exception("Unable to create statement");
		}
		
		return new Statement(cntr);
	}
	
	static IStatement prepareRaw(char[] sql, char[] key = null)
	{
		auto provider = getProvider;
		IStatement stmt;
		if(!provider.prepareRaw(sql, stmt, key)) {
			debug throw new Exception("Unable to create statement:" ~ sql);
			else throw new Exception("Unable to create statement");
		}
		
		return stmt;
	}
	
	static IStatement virtualPrepareRaw(char[] sql, char[] key = null)
	{
		auto provider = getProvider;
		IStatement stmt;
		if(!provider.virtualPrepareRaw(sql, stmt)) {
			debug throw new Exception("Unable to create statement:" ~ sql);
			else throw new Exception("Unable to create statement");
		}
		
		return stmt;
	}
	
	static void beginTransact()
	{
		auto provider = getProvider;
		provider.beginTransact;
	}
	
	static void rollback()
	{
		auto provider = getProvider;
		provider.rollback;
	}
	
	static void commit()
	{
		auto provider = getProvider;
		provider.commit;
	}
	
	static SqlGenerator sqlGen()
	{
		auto provider = getProvider;
		return provider.sqlGen;
	}
	
	static DatabaseT database()
	{
		auto provider = getProvider;
		return provider.getInstance;
	}
}

alias DBProvider!(DefaultConnectionProvider) DefaultDatabaseProvider;
version(dbi_mysql) {
	alias DBProvider!(DefaultMysqlConnectionProvider) DefaultMysqlProvider;	
}

version(dbi_mysql) {
	alias DBProvider!(DefaultSqliteConnectionProvider) DefaultSqliteProvider;	
}