/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.ConnectionPool;

import sendero.util.collection.ThreadSafeQueue;

import tango.core.Atomic;

/**
 * Class for thread safe connection pooling with variable cache size.  Uses 
 * ThreadSafeQueue class for its implementation. 
 */
class ConnectionPool(ConnectionT, ProviderT)
{
	private static Atomic!(uint) maxCacheSize;
	private static ThreadSafeQueue!(ConnectionT) queue;
	private static ConnectionT[ConnectionT] activeConnections;
	
	static this()
	{
		queue = new ThreadSafeQueue!(ConnectionT);
	}
	
	static ConnectionT getConnection()
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
	
	static void releaseConnection(ConnectionT conn)
	{
		synchronized
    {
			activeConnections.remove(conn);
    }
		
		if(queue.length >= maxCacheSize.load!(msync.seq))
			return;
		
		queue.enqueue(conn);
	}
	
	static uint getMaxCacheSize()
	{
		return maxCacheSize.load!(msync.seq);
	}
	
	static void setMaxCacheSize(uint size)
	{
		maxCacheSize.store!(msync.seq)(size);
	}
	
	static uint cacheSize()
	{
		return queue.length;
	}
}

version(Unittest)
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
}

unittest
{
	auto appender = new FileAppender("ConnectionPool_test.log");
	Log.getRootLogger.addAppender(appender);
	alias ConnectionPool!(SqliteDB, SqliteTestProvider) Pool;
	
	static class TestThread : Thread
	{
		this()
		{
			this.db = Pool.getConnection;
			super(&run);
		}
		~this()
		{
			
		}
		
		bool res = false;
		bool res2 = false;
		SqliteDB db;
		
		private void run()
		{
			if(db) res = true;
			if(db.tableExists("A")) res2 = true;
			Pool.releaseConnection(db);
		}
	}
	
	const uint maxCache = 100;
	Pool.setMaxCacheSize(maxCache);
	
	auto group = new ThreadGroup;
	const uint n = 100;
	//Stdout("Queueing " ~ Integer.toUtf8(n) ~ " threads").newline;
	
	TestThread[n] threads;
	for(uint i = 0; i < n; ++i)
	{
		threads[i] = new TestThread;
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
	assert(Pool.getMaxCacheSize == maxCache);
	
	//	Asserts that some connections were cached
	assert(Pool.cacheSize > 0);
	//Stdout(Integer.toUtf8(Pool.cacheSize) ~ " connections cached").newline;
	//Stdout(Integer.toUtf8(Pool.activeConnections.length) ~ " connections still active").newline;
	
	//Ensures that every connection that was cached was unique
	SqliteDB[SqliteDB] cacheMap;
	while(1) {
		auto x = Pool.queue.dequeue;
		if(!x)
			break;
		auto p = (x in cacheMap);
		assert(!p);
		cacheMap[x] = x;
	}
	appender.close;
}
