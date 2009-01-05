module sendero.server.tcp.model.ITcpServiceProvider;

public import sendero.server.io.StagedReadBuffer;
public import sendero.server.io.model.ICachedBuffer;

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

/+

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
	TcpResponse handleRequest(StagedReadBuffer buffer, ITcpCompletionPort completionPort);
}

interface ITcpCompletionPort
{
	void keepReading();
	void sendResponseData(TcpResponse.Type type, void[][] data...);
	void sendResponseData(TcpResponse.Type type, ICachedBuffer[][] data...);

}

abstract class TcpResponse
{
	enum Type { Continue, FinishKeepAlive, FinishClose };
	Type type;
	
	abstract void[] getNextBuffer();
	absract void release();

	static TcpResponse create(TcpResponse.Type type, void[][] data...)
	{
		return new UnmanagedTcpResponse(type,data);
	}

	static TcpResponse create(TcpResponse.Type type, ICachedBuffer[][] data...)
	{
		return new ManagedTcpResponse(type,data);
	}
}

private class UnmanagedTcpResponse : TcpResponse
{
	this(void[][]... data)
	{
		this.data_ = data;
	}
	void[][] data_;

	void release()
	{
	
	}
}

private class ManagedTcpResponse : TcpResponse
{
	
}

+/
