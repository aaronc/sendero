/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.session.Session;

public import sendero.http.Request;

import tango.core.Thread;
public import tango.net.http.HttpCookies;

version(SenderoSessionGC)
{
	public import sendero.session.GC;
}

class BasicSessionData
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
		version(SenderoSessionGC)
		{
			SessionGC.reset;
		}
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
	alias cur get;
	alias cur opCall;
}

version(Unittest)
{

alias SessionGlobal!(BasicSessionData) Session;
	
unittest
{
	
}
}