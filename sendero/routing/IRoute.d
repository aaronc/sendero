module sendero.routing.IRoute;

interface IRoute(ResT, ReqT)
{
	ResT route(ReqT);
}