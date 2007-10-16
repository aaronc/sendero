/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */

module sendero.server.SenderoProvider;

import sendero.util.http.HttpResponse;
import sendero.util.http.HttpProvider;
import sendero.util.http.HttpRequest;
import tango.net.http.HttpConst;
import tango.io.protocol.Writer;
import tango.io.Buffer;
import tango.io.Stdout;

private static const int ResponseBufferSize = 20 * 1024;


class SenderoProvider : HttpProvider
{
	Buffer outbuf;
	Writer respond;
	this()
	{
		outbuf = new Buffer(ResponseBufferSize);
	}

	void service (HttpRequest request, HttpResponse response)
	{

		outbuf("<HTML>\n<HEAD>\n<TITLE>Hello!</TITLE>\n"c)
    	 		 ("<BODY>\n<H2>This is a test</H2>\n"c)
       		 ("</BODY>\n</HTML>\n"c);
		
		response.setContentType (HttpHeader.TextHtml.value);
		response.setContentLength(outbuf.limit());
		auto buf = response.getOutputBuffer();
		buf(outbuf.slice());
		response.flush();
    outbuf.clear();
		//response.sendError(HttpResponses.NotFound);
	}
}
