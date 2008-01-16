module sendero.routing.Common;

public import sendero.util.HTTPRequest;
public import sendero.util.UrlStack;

enum HttpMethod { Get, Post };

interface IFunctionWrapper(Ret, Req)
{
	Ret exec(Req);
	Ret execDg(void*, Req);
}