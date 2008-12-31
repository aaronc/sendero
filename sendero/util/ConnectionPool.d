/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.ConnectionPool;

import sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;
/+
interface IConnectionPool(ConnectionT)
{
	ConnectionT getConnection();
	void releaseConnection(ConnectionT conn);
}

/**
 * Class for thread safe connection pooling with variable cache size.  Uses 
 * ThreadSafeQueue class for its implementation. 
 */
class ConnectionPool(ConnectionT, ProviderT) : IConnectionPool!(ConnectionT)
{
	private Atomic!(uint) maxCacheSize;
	private ThreadSafeQueue!(ConnectionT) queue;
	private ConnectionT[ConnectionT] activeConnections;
	
	this(uint maxCacheSize = 100)
	{
		queue = new ThreadSafeQueue!(ConnectionT);
		setMaxCacheSize(maxCacheSize);
	}
	
	ConnectionT getConnection()
	{
		auto conn = queue.dequeue;
		if(conn)
			return conn;
		
		conn = ProviderT.createNewConnection;
		synchronized
		{
			activeConnections[conn] = conn;
		}
		return conn;
	}
	alias getConnection get;
	
	void releaseConnection(ConnectionT conn)
	{
		synchronized
		{
			activeConnections.remove(conn);
		}
		
		if(queue.length >= maxCacheSize.load!(msync.seq)) {
			static if(is(typeof(ProviderT.release)))
				ProviderT.release(conn);
			return;
		}
		
		queue.enqueue(conn);
	}
	alias releaseConnection release;
	
	uint getMaxCacheSize()
	{
		return maxCacheSize.load!(msync.seq);
	}
	
	void setMaxCacheSize(uint size)
	{
		maxCacheSize.store!(msync.seq)(size);
	}
	
	uint cacheSize()
	{
		return queue.length;
	}
}+/

abstract class ConnectionPool(ConnT)
{
	this()
	{
		queue_ = new ThreadSafeQueue!(ConnT);
	}
	
	alias ConnT ConnectionT;
	
	final uint maxCacheSize() { return maxCacheSize_; }
	final void maxCacheSize(uint sz) { maxCacheSize_ = sz; }	
	
	abstract ConnT createNewConnection();
	
	final ConnT get() in {
		assert(queue_ !is null);
	}
	body {
		auto conn = queue_.pull;
		if(conn !is null) {
			atomicDecrement(cacheSize_);
			connMap_.remove(conn);
			return conn;
		}
		else return createNewConnection;
	}
	
	final void release(ConnT conn) in {
		assert(queue_ !is null);
	}
	body {
		if(atomicLoad(cacheSize_) < maxCacheSize_) {
			auto pConn = conn in connMap_;
			if(pConn) {
				throw new Exception("Trying to place connection "
					" in the pool a second time in class "
					~ typeof(this).stringof);
			}
			queue_.push(conn);
			connMap_[conn] = conn;
			atomicIncrement(cacheSize_);
		}
		else delete conn;
	}
	
	final uint cacheSize()
	{
		return cacheSize_;
	}
	
private:
	ConnT[ConnT] connMap_;
	ThreadSafeQueue!(ConnT) queue_;
	uint maxCacheSize_ = 100;
	uint cacheSize_;
}

/+version(Unittest)
{
	import sendero.data.backends.Sqlite;
	class SqliteTestProvider
	{
		static SqliteDB createNewConnection()
		{
			return SqliteDB.connect("sendero_test.db");
		}
	}
	
	import tango.core.Thread;
	import Integer = tango.text.convert.Integer;
	import tango.io.Stdout;
	import tango.util.log.Log;
	import tango.util.log.FileAppender;

unittest
{
	auto appender = new FileAppender("ConnectionPool_test.log");
	Log.getRootLogger.addAppender(appender);
	
	static class TestThread : Thread
	{
		this(ConnectionPool!(SqliteDB, SqliteTestProvider) pool)
		{
			this.pool = pool;
			this.db = pool.getConnection;
			super(&run);
		}
		~this()
		{
			
		}
		
		bool res = false;
		bool res2 = false;
		SqliteDB db;
		ConnectionPool!(SqliteDB, SqliteTestProvider) pool;
		
		private void run()
		{
			if(db) res = true;
			if(db.tableExists("A")) res2 = true;
			pool.releaseConnection(db);
		}
	}
	
	auto pool = new ConnectionPool!(SqliteDB, SqliteTestProvider);
	const uint maxCache = 100;
	pool.setMaxCacheSize(maxCache);
	
	auto group = new ThreadGroup;
	const uint n = 100;
	//Stdout("Queueing " ~ Integer.toUtf8(n) ~ " threads").newline;
	
	TestThread[n] threads;
	for(uint i = 0; i < n; ++i)
	{
		threads[i] = new TestThread(pool);
		group.add(threads[i]);
		threads[i].start;
	}
	group.joinAll;
	
	//	Ensures that every connection was valid
	for(uint i = 0; i < n; ++i)
	{
		assert(threads[i].res, Integer.toUtf8(i));
	}
	
	//	Ensures that every thread did its job successfully
	for(uint i = 0; i < n; ++i)
	{
		assert(threads[i].res2, Integer.toUtf8(i));
	}
	
	//	Asserts that the maxCacheSize was properly set
	assert(pool.getMaxCacheSize == maxCache);
	
	//	Asserts that some connections were cached
	assert(pool.cacheSize > 0);
	//Stdout(Integer.toUtf8(Pool.cacheSize) ~ " connections cached").newline;
	//Stdout(Integer.toUtf8(Pool.activeConnections.length) ~ " connections still active").newline;
	
	//Ensures that every connection that was cached was unique
	SqliteDB[SqliteDB] cacheMap;
	while(1) {
		auto x = pool.queue.dequeue;
		if(!x)
			break;
		auto p = (x in cacheMap);
		assert(!p);
		cacheMap[x] = x;
	}
	appender.close;
}
}+/