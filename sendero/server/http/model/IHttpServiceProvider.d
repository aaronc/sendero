module sendero.server.http.model.IHttpServiceProvider;

public import sendero.server.http.model.IHttpRequestHandler;

interface IHttpServiceProvider
{
	IHttpRequestHandler handleHttpRequest(void[][] data);
}