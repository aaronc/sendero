module sendero.server.model.ITcpServiceProvider;

public import sendero.server.io.StagedReadBuffer;

interface ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler();
	void cleanup(ITcpRequestHandler);
}

alias void delegate(void[]) TcpBufferCleanupDgT;

class TcpResponse
{
	enum { Continue, FinishKeepAlive, FinishDisconnect }
	void[][] data;
	bool keepAlive = true;
	int type;
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
