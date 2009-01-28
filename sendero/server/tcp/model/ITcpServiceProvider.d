module sendero.server.tcp.model.ITcpServiceProvider;

public import sendero.server.io.StagedReadBuffer;
public import sendero.server.io.model.ICachedBuffer;

/+
interface ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler();
	void cleanup(ITcpRequestHandler);
}

alias void delegate(void[]) TcpBufferCleanupDgT;

class TcpResponse
{
	enum Type { Continue, FinishKeepAlive, FinishClose }
	void[][] data;
	bool keepAlive = true;
	Type type;
	TcpBufferCleanupDgT dg;
}

alias TcpResponse SyncTcpResponse;

interface ITcpRequestHandler
{
	/**
	 * 
	 * Params:
	 *     data = incoming data from client
	 *     completionPort = completion port for asynchronous response 
	 * Returns:
	 * response data for synchronous handling, or null to indicate that
	 * response will be sent asynchonously
	 */
	SyncTcpResponse handleRequest(StagedReadBuffer buffer, ITcpCompletionPort completionPort);
	
	//SyncTcpResponse initRequest(StagedReadBuffer buffer, ITcpCompletionPort completionPort);
	//SyncTcpResponse onNewData();
}

interface ITcpCompletionPort
{
	void keepReading();
	void sendResponseData(void[][] data);
	void endResponse(bool keepAlive = true);
	//void sendResponseData(TcpResponse type, TcpBufferCleanupDgT cleanupDg, void[][] data...);
}
+/

interface ITcpRequestHandler
{
	/**
	 * 
	 * Params:
	 *     data = incoming data from client
	 *     completionPort = completion port for asynchronous response 
	 * Returns:
	 * response data for synchronous handling, or null to indicate that
	 * response will be sent asynchonously
	 */
	SyncTcpResponse handleRequest(IAsyncTcpConduit connection);
}

interface IAsyncTcpConduit
{
	void keepReading();
	void keepReading(ITcpRequestHandler handler);
	void sendResponseData(TcpAction whenDone, void[][] data...);
	void sendResponseData(TcpAction whenDone, ICachedBuffer data);
	StagedReadBuffer requestData();
	CachedBuffer responseBuffer();
}

enum TcpAction { None, WaitForRead, Close };

class SyncTcpResponse
{
	this(TcpAction whenDone, ICachedBuffer data)
	{
		this.type = type;
		this.data = data;
	}
	
	TcpAction whenDone;	
	ICachedBuffer data;

	static TcpResponse create(TcpAction whenDone, void[][] data...)
	{
		ICachedBuffer wrapper;
		if(data.length) {
			wrapper = new NotCachedBuffer(data);
			for(size_t i = 1; i < data.length; ++i)
			{
				
			}
		}
		else wrapper = null;
		
		return new SyncTcpResponse(whenDone,wrapper);
	}

	static TcpResponse create(TcpAction whenDone, ICachedBuffer data)
	{
		return new SyncTcpResponse(whenDone,data);
	}
}
/+
private class UnmanagedTcpResponse : TcpResponse
{
	this(TcpResponse.Type type, void[][] data...)
	{
		this.type = type;
		this.data = data;
	}
	void[][] data;
	
	ICachedBuffer getData()
	{
		
	}
}

private class ManagedTcpResponse : TcpResponse
{
	this(TcpResponse.Type type, ICachedBuffer data)
	{
		this.type = type;
		this.data_ = data;
	}
	ICachedBuffer data;
	
	ICachedBuffer getData()
	{
		return data;
	}
}

+/