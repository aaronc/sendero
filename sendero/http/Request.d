/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Request;

public import sendero.http.Params;
public import sendero.http.UrlStack;
public import sendero.http.IRenderable;
public import sendero.http.Response;

debug {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRouting");
	}
}

enum HttpMethod { Get, Post, Put, Delete };

final class Request
{
	this()
	{
		
	}
	
	void parse(HttpMethod method, char[] url, char[] getParams, char[] postParams = null)
	{
		if(method == HttpMethod.Get) {
			debug log.trace("Req.parse url:{}, getParams:{}", url, getParams);
			this.method = method;
			this.url = UrlStack.parseUrl(url);
			this.params = parseParams(getParams);
		}
		else if(method == HttpMethod.Post) {
			debug log.trace("Req.parse url:{}, getParams:{},postParams:{}", url, getParams, postParams);
			this.method = method;
			this.url = UrlStack.parseUrl(url);

			this.params = parseParams(postParams);
			auto _get_ = parseParams(getParams);
			Var _get_Var; set(_get_Var, _get_);
			this.params["@get"] = _get_Var;
		}
	}
	
	void reset()
	{
 		params = null;
		url = null;
		lastToken = null;
		cookies = null;
		ip = null;
	}
	
	IObject params;
	HttpMethod method;
	UrlStack url;
	char[] lastToken;
	char[][char[]] cookies;
	char[] ip;
	char[][char[]] headers;
	
	void setResponder(IResponder responder)
	{
		responder_ = responder;
	}
	
	void delegate(void[]) getConsumer()
	{
		assert(responder_, "responder_ is null");
		return &responder_.write;
	}
	
	void setContentType(char[] contentType)
	{
		assert(responder_,  "responder_ is null");
		responder_.setContentType(contentType);
	}
	
	void respond(IRenderable r)
	{
		responder_.setContentType(r.contentType);
		r.render(&responder_.write);
	}
	
	void respond(IStream s, char[] contentType)
	{
		responder_.setContentType(contentType);
		s.render(&responder_.write);
	}
	
	void respond(void delegate(void delegate(void[])) stream, char[] contentType = ContentType.TextHtml)
	{
		responder_.setContentType(contentType);
		stream(&responder_.write);
	}
	
	void respond(char[] content, char[] contentType = ContentType.TextHtml)
	{
		responder_.setContentType(contentType);
		responder_.write(content);
	}
	
	void setCookie(char[] name, char[] value)
	{
		responder_.setCookie(name, value);
	}
	
	void setCookie(Cookie cookie)
	{
		responder_.setCookie(cookie);
	}
	
	alias respond render;
	
	private:
		IResponder responder_;
}

alias Request Req;

interface IHttpSet
{
	void httpSet(IObject param, Request req);
}