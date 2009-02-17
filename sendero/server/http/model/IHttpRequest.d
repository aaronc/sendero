module sendero.server.http.model.IHttpRequest;

interface IHttpRequest
{
	// headers
	// params
	// uri
	IParamsView params();
	IHttpResponder response();
}

interface IParamsView
{
	char[] opIndex(char[] param);
	int opApply(int delegate(char[],char[]));
}