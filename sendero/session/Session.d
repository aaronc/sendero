module sendero.session.Session;

import sendero.http.Request;

import tango.core.Thread;
import tango.net.http.HttpCookies;

class BasicSessionImp
{
	this()
	{
		req = new Request;
	}
	
	Request req;
	
	Cookie[] cookies;
	
	void setCookie(char[] name, char[] value)
	{
		cookies ~= new Cookie(name, value);
	}
	
	void setCookie(Cookie cookie)
	{
		cookies ~= cookie;
	}
	
	void reset()
	{
		cookies.length = 0;
		req.reset;
	}
}

class SessionGlobal(SessionImpT)
{
	static ThreadLocal!(SessionImpT) data;
	static this()
	{
		data = new ThreadLocal!(SessionImpT);
	}
	
	static SessionImpT cur()
	{
		auto session = data.val;
		if(!session) {
			session = new SessionImpT;
			data.val = session;
		}
		return session;
	}
	alias cur opCall;
}

version(Unittest)
{

alias SessionGlobal!(BasicSessionImp) Session;
	
unittest
{
	
}
}