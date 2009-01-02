module sendero.server.model.ITcpServiceProvider;

public import sendero.server.io.StagedReadBuffer;

interface ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler();
	void cleanup(ITcpRequestHandler);
}

class SyncTcpResponse
{
	void[][] data;
	bool keepAlive = true;
}

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
}
