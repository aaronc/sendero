module sendero.routing.IRoute;

import sendero.http.Request;

interface IIRoute(ReqT)
{
	void iroute(ReqT);
}

alias IIRoute!(Req) IIController;