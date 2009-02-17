module sendero.server.http.model.IHttpRequestHandler;

public import sendero.server.tcp.model.ITcpServiceProvider;

struct HttpRequestLineData
{
	char[] method;
	char[] uri;
	char[] path;
	char[] queryString;
	char[] fragment;
	char[] httpVersion;
}

interface IHttpRequestData
{
	size_t expectedContentLength();
	bool chunked();
	void[] nextContentBuffer();
	void releaseContentBuffer(void[]);
}

interface IHttpRequestHandler
{
	void handleRequestLine(HttpRequestLineData data);
	void handleHeader(char[] field, char[] value);
	//void handleData(void[][] data);
	void signalFatalError();
	SyncTcpResponse processRequest(IHttpRequestData data, ITcpCompletionPort completionPort);
}
