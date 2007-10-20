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
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;

private static const int ResponseBufferSize = 20 * 1024;


class SenderoProvider : HttpProvider
{
	Buffer outbuf;
	Logger logger;
	this()
	{
		logger = Log.getLogger("SenderoProvider");
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
		logger.info("flushing output buffer");
		response.flush();
    outbuf.clear();
		//response.sendError(HttpResponses.NotFound);
	}

}

class SenderoProviderFactory : ProviderFactory
{
	HttpProvider get()
	{
		return new SenderoProvider();
	}
}
