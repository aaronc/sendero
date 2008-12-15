module sendero.server.model.IHttpRequestHandler;

public import sendero.server.model.ITcpServiceProvider;

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
	void signalFatalError();
	void[][] processRequest(ITcpCompletionPort completionPort);
}
