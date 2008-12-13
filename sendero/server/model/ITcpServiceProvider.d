module sendero.server.model.ITcpServiceProvider;

interface ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler();
}

interface ITcpRequestHandler
{
	void handleData(void[][] data);
	
	/**
	 * 
	 * Params:
	 *     completionPort = completion port for asynchronous response 
	 * Returns:
	 * response data for synchronous handling, or null to indicate that
	 * response will be sent asynchonously
	 */
	void[][] processRequest(ITcpCompletionPort completionPort);
	
	void cleanup();
}

interface ITcpCompletionPort
{
	void keepReading();
	void sendResponseData(void[][] data);
	void endResponse(bool keepAlive = true);
}
