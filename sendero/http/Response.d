/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Response;

public import tango.net.http.HttpCookies;

interface IResponder
{
	void setContentType(char[] contentType);
	void write(void[] val);
	void setCookie(char[] name, char[] value);
	void setCookie(Cookie cookie);
}

struct ContentType
{
	const char[] TextHtml = "text/html; charset=utf-8";
	const char[] TextXml = "text/xml";
	const char[] TextJSON = "text/json";
	const char[] AppJS = "application/javascript";
	
}
alias ContentType Mime;


class Responder : IResponder
{
	void setContentType(char[] contentType)
	{
		this.contentType = contentType;
	}
	
	void write(void[] val)
	{
		res ~= val;
	}
	
	void setCookie(char[] name, char[] value)
	{
		
	}
	
	void setCookie(Cookie cookie)
	{
		
	}
	
	void reset()
	{
		res.length = 0;
		contentType = Mime.TextHtml;
	}
	
	void[] res;
	char[] contentType;
}

/+

struct Response
{
	const char[] TextHtml = "text/html; charset=utf-8";
	const char[] TextXml = "text/xml";
	const char[] TextJSON = "text/json";
	const char[] AppJS = "application/javascript";
	
	char[] contentType = TextHtml;
	void delegate(void delegate(void[])) contentDelegate;
	void render(void delegate(void[]) consumer)
	{
		consumer("Content-type: ");
		consumer(contentType);
		consumer("\r\n\r\n");
		
		contentDelegate(consumer);
	}
}
alias Response Res;+/