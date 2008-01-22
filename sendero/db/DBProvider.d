module sendero.db.DBProvider;

import dbi.PreparedStatement;
import tango.core.Thread;
import sendero.util.ConnectionPool;

public import sendero.db.Statement;


/*

interface IDBConnectionProvider
{
	IPreparedStatementProvider createNewConnection();
}
*/

interface IProvider(StatementT)
{
	bool prepare(char[] statement, inout StatementT stmt, char[] key = null);
	bool prepareRaw(char[] statement, inout IPreparedStatement stmt, char[] key = null);
}

class ProviderContainer(ConnectionT, ProviderT, StatementT) : IProvider!(StatementT)
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
	
	bool prepareRaw(char[] statement, inout IPreparedStatement stmt, char[] key = null)
	{
		IPreparedStatement* pStmt = null;
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
	
	private ConnectionT inst;
	private StatementT[char[]] cachedStatements;
	private IPreparedStatement[char[]] cachedRawStatements;
	
	~this()
	{
		ProviderT.releaseConnection(inst);
	}
}



class DBProvider(DBConnectionProvider)
{
	private static this()
	{
		pool = new ConnectionPool!(IPreparedStatementProvider, DBConnectionProvider);
		providers_ = new ThreadLocal!(ProviderContainer!(IPreparedStatementProvider, DBProvider!(DBConnectionProvider), StatementContainer))(null);
	}
	
	private static ConnectionPool!(IPreparedStatementProvider, DBConnectionProvider) pool;
	private static ThreadLocal!(ProviderContainer!(IPreparedStatementProvider, DBProvider!(DBConnectionProvider), StatementContainer)) providers_;
	
	private static IProvider!(StatementContainer) getProvider()
	{
		debug assert(providers_);
		auto provider = providers_.val;
		if(!provider) {
			auto conn = pool.getConnection;
			debug assert(conn);
			if(!conn) return null;
			provider = new ProviderContainer!(IPreparedStatementProvider, DBProvider!(DBConnectionProvider), StatementContainer)(conn);
			debug assert(provider);
			providers_.val = provider;
		}
		return provider;
	}
	
	static void releaseConnection(IPreparedStatementProvider conn)
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
	
	static IPreparedStatement prepareRaw(char[] sql, char[] key = null)
	{
		auto provider = getProvider;
		IPreparedStatement stmt;
		if(!provider.prepareRaw(sql, stmt, key)) {
			debug throw new Exception("Unable to create statement:" ~ sql);
			else throw new Exception("Unable to create statement");
		}
		
		return stmt;
	}
}

