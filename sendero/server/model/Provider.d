module sendero.server.model.Provider;

interface IAsyncServiceProvider
{
	void handle(void[][] data, IAsyncResponder)
}

interface ISyncServiceProvider
{
	void[][] handle(void[][] data);
}

interface IAsyncResponder
{
	void respond(void[][] response);
}

interface IServiceProvider
{
	//void[][] handle(void[][] data, ITcpCompletionPort completionPort);
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
}

interface ITcpCompletionPort
{
	void keepReading();
	void sendResponseData(void[][] data);
	void endResponse(bool keepAlive = true);
}
