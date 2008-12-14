module sendero.server.model.IHttpServiceProvider;

import sendero.server.model.ITcpServiceProvider;

interface IHttpServiceProvider
{
	IHttpRequestHandler handleHttpRequest(void[][] data);
}

/+interface IHttpCompletionPort
{
	void sendResponseData(void[][] data);
	void endResponse(bool keepAlive = true);
}+/

struct HttpRequestLineData
{
	char[] method;
	char[] uri;
	char[] path;
	char[] queryString;
	char[] fragment;
	char[] httpVersion;
}

interface IHttpRequestHandler
{
	void handleRequestLine(HttpRequestLineData data);
	void handleHeader(char[] field, char[] value);
	void handleData(void[][] data);
	//void processRequest(HttpCompletionCallback callback);
	//void[][] processRequest();
	//void[][] processRequest(IHttpCompletionCallback callback);
	void[][] processRequest(ITcpCompletionPort completionPort);
}
