module sendero.server.model.ITcpServiceProvider;

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
	SyncTcpResponse handleRequest(void[][] data, ITcpCompletionPort completionPort);
}

interface ITcpCompletionPort
{
	void keepReading();
	void sendResponseData(void[][] data);
	void endResponse(bool keepAlive = true);
}
