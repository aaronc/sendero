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
	bool prepare(char[] statement, inout StatementT stmt);
}

class ProviderContainer(ConnectionT, ProviderT, StatementT) : IProvider!(StatementT)
{
	this(ConnectionT inst)
	{
		this.inst = inst;
	}
	
	bool prepare(char[] statement, inout StatementT stmt)
	{
		auto pStmt = statement in cachedStatements;
		if(pStmt) {
			stmt = *pStmt;
			return true;
		}
		
		auto rawStmt = inst.prepare(statement);
		if(!rawStmt)
			return false;
		
		stmt = StatementT(rawStmt);
		//debug assert(stmt);
		cachedStatements[statement] = stmt;
		return true;
	}
	
	private ConnectionT inst;
	private StatementT[char[]] cachedStatements;
	
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
		
	static Statement prepare(char[] sql)
	{
		auto provider = getProvider;
		StatementContainer cntr;
		if(!provider.prepare(sql, cntr))
			return null;
		
		return new Statement(cntr);
	}
}

