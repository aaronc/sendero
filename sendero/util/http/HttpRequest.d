/*******************************************************************************

copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

license:        BSD style: $(LICENSE)

version:        Initial release: April 2004      

author:         Kris

 *******************************************************************************/

module sendero.util.http.HttpRequest;

private import  Text = tango.text.Util;

private import  Integer = tango.text.convert.Integer;

private import  tango.text.stream.LineIterator;
private import  tango.io.Stdout;
private import  tango.io.Buffer,
				tango.core.Exception;

private import  tango.io.protocol.Reader,
				tango.io.protocol.model.IWriter,
				tango.io.protocol.Writer;

private import  tango.net.Uri;

private import  tango.net.http.HttpHeaders,
				tango.net.http.HttpCookies,
				tango.net.http.HttpTriplet;

private import  sendero.util.http.HttpMessage,
				sendero.util.http.ServiceBridge,
				sendero.util.http.HttpQueryParams;              
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;
/******************************************************************************

	Define an http request from a user-agent (client). Note that all
	data is managed on a thread-by-thread basis.

 ******************************************************************************/

class HttpRequest : HttpMessage, IWritable
{
	private int                     port;
	private char[]                  host;
	private bool                    mimed,
					uried,
					gulped;

	// these are per-thread instances also
	private Uri                     uri;
	private LineIterator!(char)     line;
	private HttpQueryParams         params;
	private HttpCookiesView         cookies;
	private StartLine               startLine;

	private Logger 					logger;
	private Sprint!(char) 	sprint;
	static private InvalidStateException InvalidState;

	/**********************************************************************

		Setup exceptions and so on

	 **********************************************************************/

	static this()
	{
		InvalidState = new InvalidStateException("Invalid request state");
	}

	/**********************************************************************

		Create a Request instance.  Note that we create a bunch of
		internal support objects on a per-thread basis. This is so
		we don't have to create them on demand; however, we should
		be careful about resetting them all before each new usage.

	 **********************************************************************/

	this (ServiceBridge bridge)
	{
		super (bridge, null);

		// workspace for parsing the request URI
		uri = new Uri; 

		// HTTP request start-line (e.g. "GET / HTTP/1.1")      
		startLine = new StartLine;

		// input parameters, parsed from the query string
		params = new HttpQueryParams;

		// construct a line tokenizer
		line = new LineIterator!(char);

		// Cookie parser. This is a wrapper around the Headers
		cookies = new HttpCookiesView (getHeader);
		sprint = new Sprint!(char);
		logger = Log.getLogger("HttpRequest");
	}

	/**********************************************************************

		Reset this request, ready for the next connection

	 **********************************************************************/

	void reset()
	{
		port = Uri.InvalidPort;
		host = null;
		uried = false;
		mimed = false;
		gulped = false;

		uri.reset();
		super.reset();
		params.reset();
		cookies.reset();
	}

	/**********************************************************************

		Return the HTTP startline from the connection request

	 **********************************************************************/

	StartLine getStartLine()
	{
		return startLine;
	}

	/**********************************************************************

		Return the request Uri as an immutable version ...

	 **********************************************************************/

	Uri getRequestUri()
	{
		if (! uried)
		{
			uri.parse (startLine.getPath);
			if (uri.getScheme() is null)
				uri.setScheme (getServerScheme);
			uried = true;
		}
		return uri;
	}

	/**********************************************************************

		Ensure the uri has a host present. Return as an immutable 

	 **********************************************************************/

	Uri getExplicitUri()
	{
		getRequestUri();

		if (uri.getHost is null)
			uri.setHost (getHost);
		return uri;
	}

	/**********************************************************************

		Return the buffer holding the request input. This sets a 
		boundary sentinel, indicating we're finished processing
		the input headers. You can't read headers after accessing
		this method

	 **********************************************************************/

	IBuffer getInput()
	{
		// User is reading input. Cannot read headers anymore
		gulped = true;
		return super.getBuffer;
	}

	/**********************************************************************

		Return the set of parsed request cookies

	 **********************************************************************/

	HttpCookiesView getInputCookies()
	{
		if (gulped)
			throw InvalidState;
		return cookies;
	}

	/**********************************************************************

		Return the set of parsed input headers

	 **********************************************************************/

	HttpHeadersView getInputHeaders()
	{
		if (gulped)
			throw InvalidState;
		return getHeader();
	}

	/**********************************************************************

		Return the set of input parameters, from the query string
		and/or from POST data.

	 **********************************************************************/

	HttpParamsView getInputParameters()
	{
		// parse Query or Post parameters
		if (! params.isParsed)
		{
			char[] query = getRequestUri.getQuery();

			// do we have a query string?
			if (query.length)
				// yep; parse that
				params.parse (query);
			else
				// nope; do we have POST parameters?
				if (startLine.getMethod() == "POST" && 
						super.getContentType() == "application/x-www-form-urlencoded")
				{
					// yep; parse from input buffer
					int length = getHeader.getInt (HttpHeader.ContentLength);
					if (length < 0)
						throw new IOException ("No params supplied for http POST");
					else
						if (length > HttpHeader.MaxPostParamSize)
							throw new IOException ("Post parameters exceed maximum length");
						else
						{
							char[] c = cast(char[]) getBuffer.slice (length);
							if (c)
								params.parse (uri.decode (Text.replace(c, '+', ' ')));
							else
								throw new IOException ("Post parameters exceed buffer size");
						}
				}
		}
		return params;
	}

	/**********************************************************************

		Return the buffer attached to the input conduit. This
		also sets a sentinel indicating we cannot read headers 
		anymore.

	 **********************************************************************/

	IBuffer getInputBuffer()
	{
		// User is reading input. Cannot read headers anymore
		gulped = true;
		return super.getBuffer();
	}

	/**********************************************************************

		Write the startline and all input headers to the provider
		IWriter. This can be used for debug purposes.

	 **********************************************************************/

	void write (IWriter writer)
	{
		startLine.write (writer);
		super.write (writer);
	}

	/**********************************************************************

		Parse all headers from the input.

	 **********************************************************************/

	void readHeaders()
	{

		auto input = super.getBuffer();

		line.set (input);

		// skip any blank lines
		while (line.next && line.get.length is 0) 
		{}

		// is this a bogus request?
		if (input.readable() == 0)
			throw new IOException ("truncated request");

		// load HTTP request
		startLine.parse (line.get);

		// populate headers
		getHeader().parse (input);

		//super.write(logger.info);

	}

	/**********************************************************************

		Proxy this request across to the server instance 

	 **********************************************************************/

	char[] getRemoteAddr()
	{
		return getBridge().getServer().getRemoteAddress(getConduit);
	}

	/**********************************************************************

		Proxy this request across to the server instance 

	 **********************************************************************/

	char[] getRemoteHost()
	{
		return getBridge().getServer().getRemoteHost(getConduit);
	}

	/**********************************************************************

		Ask the server instance what protocol it is using

	 **********************************************************************/

	char[] getServerScheme()
	{
		return getBridge().getServer().getProtocol();
	}

	/**********************************************************************

		Return the encoding from the input headers.

	 **********************************************************************/

	char[] getEncoding()
	{
		getMimeType();
		return super.getEncoding();
	}

	/**********************************************************************

		Return the mime-type from the input headers.

	 **********************************************************************/

	char[] getMimeType()
	{
		if (! mimed)
		{
			setMimeAndEncoding (super.getContentType());
			mimed = true;
		}
		return super.getMimeType();
	}

	/**********************************************************************

		Return the port number this request was sent to.

	 **********************************************************************/

	int getPort()
	{
		if (port == Uri.InvalidPort)
		{
			getHost();
			if (port == Uri.InvalidPort)
				// return port from server connection
				port = getBridge().getServer().getPort();
		}
		return port;
	}

	/**********************************************************************

		Get the host name. If we can't get it from the Uri, then
		we try to extract for the host header. Failing that, we
		ask the server instance to provide it for us.

	 **********************************************************************/

	char[] getHost()
	{
		// return previously determined host
		if (host.length)
			return host;

		// return host from absolute uri (make sure we parse it first)
		Uri uri = getRequestUri ();

		host = uri.getHost ();
		port = uri.getPort ();
		if (host.length)
			return host;

		// return host from header field
		host = Text.trim (getHeader().get(HttpHeader.Host));
		port = Uri.InvalidPort;

		if (host.length)
		{
			auto colon = Text.locate (host, ':');
			if (colon < host.length)
			{
				port = cast(int) Integer.convert (host[colon+1 .. $]);
				host = host[0 .. colon];
			}
		}
		else
			// return host from server connection
			host = getBridge().getServer().getHost();

		return host;
	}
}


/******************************************************************************

	Class to represent an HTTP start-line

 ******************************************************************************/

private class StartLine : HttpTriplet
{
	/**********************************************************************

		test the validity of these tokens

	 **********************************************************************/

	void test ()
	{
		if (! (tokens[0].length && tokens[1].length && tokens[2].length))
			error ("Invalid HTTP request: ");                 
	}

	/**********************************************************************

		Return the request method

	 **********************************************************************/

	char[] getMethod()
	{
		return tokens[0];
	}

	/**********************************************************************

		Return the request path

	 **********************************************************************/

	char[] getPath()
	{
		return tokens[1];
	}

	/**********************************************************************

		Return the request protocol

	 **********************************************************************/

	char[] getProtocol()
	{
		return tokens[2];
	}
}

