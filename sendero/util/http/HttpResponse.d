/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.util.http.HttpResponse;

private import  tango.io.Buffer;

private import  tango.net.http.HttpConst,
                tango.net.http.HttpParams,
                tango.net.http.HttpCookies,
                tango.net.http.HttpHeaders;

private import  tango.io.protocol.model.IWriter,
								tango.io.Stdout,
				        tango.io.protocol.Writer;

private import  sendero.util.http.HttpMessage,
                sendero.util.http.ServiceBridge;

private import  Integer = tango.text.convert.Integer;

//version = ShowHeaders;

/*******************************************************************************

        Some constants for output buffer sizes

*******************************************************************************/

private static const int ParamsBufferSize = 1 * 1024;
private static const int HeaderBufferSize = 4 * 1024;

/******************************************************************************

        Define an http response to a user-agent (client). Note that all
        data is managed on a thread-by-thread basis.

******************************************************************************/

class HttpResponse : HttpMessage
{
        private HttpParams      params;
        private HttpCookies     cookies;
        private HttpStatus      status;
        private IBuffer         output;
        private bool            commited;
				private int							hdrsize;
        static private InvalidStateException InvalidState;

        /**********************************************************************

                Construct static instances of exceptions etc. 

        **********************************************************************/

        static this()
        {
                InvalidState = new InvalidStateException("Invalid response state");
        }

        /**********************************************************************

                Create a Response instance. Note that we create a bunch of
                internal support objects on a per-thread basis. This is so
                we don't have to create them on demand; however, we should
                be careful about resetting them all before each new usage.

        **********************************************************************/

        this (ServiceBridge bridge)
        {
                // create a seperate output buffer for headers to reside
                super (bridge, new Buffer(HeaderBufferSize));

                // hang onto the output buffer
                output = super.getBuffer;

                // create a cached query-parameter processor. We
                // support a maximum output parameter list of 1K bytes
                params = new HttpParams (new Buffer(ParamsBufferSize));
        
                // create a wrapper for output cookies. This is more akin 
                // to a specialized writer, since it just adds additional
                // content to the output headers.
                cookies = new HttpCookies (super.getHeader);
        }

        /**********************************************************************

                Reset this response, ready for the next connection

        **********************************************************************/

        void reset()
        {
                // response is "OK" by default
                commited = false;
                setStatus (HttpResponses.OK);

                // reset the headers
                super.reset;

                // reset output parameters
                params.reset;
        }

        /**********************************************************************

                Send an error status to the user-agent

        **********************************************************************/

        void sendError (inout HttpStatus status)
        {
                sendError (status, "");
        }

        /**********************************************************************

                Send an error status to the user-agent, along with the
                provided message

        **********************************************************************/

        void sendError (inout HttpStatus status, char[] msg)
        {       
                sendError (status, status.name, msg);
        }

        /**********************************************************************

                Send an error status to the user-agent, along with the
                provided exception text

        **********************************************************************/

        void sendError (inout HttpStatus status, Exception ex)
        {
                sendError (status, status.name, ex.toUtf8);
        }

        /**********************************************************************

                Set the current response status.

        **********************************************************************/

        void setStatus (inout HttpStatus status)
        {
                this.status = status;
        }

        /**********************************************************************

                Return the current response status

        **********************************************************************/

        HttpStatus getStatus ()
        {
                return status;
        }

        /**********************************************************************

                Return the wrapper for adding output parameters

        **********************************************************************/

        HttpParams getOutputParams()
        {
                return params;
        }

        /**********************************************************************

                Return the wrapper for output cookies

        **********************************************************************/

        HttpCookies getOutputCookies()
        {
                return cookies;
        }

        /**********************************************************************

                Return the wrapper for output headers.

        **********************************************************************/

        HttpHeaders getOutputHeaders()
        {
                // can't access headers after commiting
                if (commited)
                    throw InvalidState;
                return super.getHeader;
        }

        /**********************************************************************

                Return the buffer attached to the output conduit. Note that
                further additions to the output headers is disabled from
                this point forward. 

        **********************************************************************/

        IBuffer getOutputBuffer()
        {
                // write headers, and cause InvalidState 
                // on next call to getOutputHeaders()
                commit;
                return output;
        }

				/**********************************************************************

					Set the content length, this should always be done since we do not
					close the connection after the response is complete 

				***********************************************************************/

				void setContentLength(int len)
				{
					char tmp[16] = void;
					getHeader().add(HttpHeader.ContentLength, Integer.itoa(tmp, len)); 
				}
        /**********************************************************************

                Send a redirect response to the user-agent

        **********************************************************************/

        void sendRedirect (char[] location)
        {
                setStatus (HttpResponses.MovedTemporarily);
                getHeader().add (HttpHeader.Location, location);
                flush ();
        }

        /**********************************************************************

                Write the response and the output headers 

        **********************************************************************/

        void write (IWriter writer)
        {
                commit (writer.buffer);
        }

        /**********************************************************************

                Ensure the output is flushed

        **********************************************************************/

        void flush ()
        {
                commit (output);

                version (ShowHeaders)
                        {
                        Stdout.formatln ("###############");
                        Stdout.formatln (cast(char[])output.slice);
                        Stdout.formatln ("###############");
                        }
               output.flush;
        }

        /**********************************************************************

                Private method to send the response status, and the
                output headers, back to the user-agent

        **********************************************************************/

        private void commit ()
        {
                commit(output);
        }

        private void commit (IBuffer emit)
        {
                if (! commited)
                   {
                   // say we've send headers on this response
                   commited = true;

                   char[16]     tmp;
                   char[]       header;
                   HttpHeaders  headers = getHeader;

                   // write the response header
                   emit (HttpHeader.Version.value)
                        (" ")
                        (Integer.itoa (tmp, status.code))
                        (" ")
                        (status.name)
                        (HttpConst.Eol);

                   // tell client we don't support keep-alive
                   //if (! headers.get (HttpHeader.Connection))
                   //      headers.add (HttpHeader.Connection, "close");
									 
									 // write the header tokens, followed by a blank line
                   super.produce (&emit.consume, HttpConst.Eol);

                   // send headers back to the UA right away
                   emit (HttpConst.Eol).flush;
                        
                   version (ShowHeaders)
                           {
                           Stdout.formatln (">>>> output headers");
                           Stdout.formatln (HttpHeader.Version.value);
                           Stdout.formatln (" {} ",status.code);
                           Stdout.formatln (status.name);
                           super.write(new Writer(Stdout.stream));
                           }
                   }

        }

        /**********************************************************************

                Send an error back to the user-agent. We have to be careful
                about which errors actually have content returned and those
                that don't.

        **********************************************************************/

        private void sendError (inout HttpStatus status, char[] reason, char[] message)
        {
                setStatus (status);

                if (status.code != HttpResponses.NoContent.code && 
                    status.code != HttpResponses.NotModified.code && 
                    status.code != HttpResponses.PartialContent.code && 
                    status.code >= HttpResponses.OK.code)
                   {
                   // error-page is html
                   setContentType (HttpHeader.TextHtml.value);

                   // output the headers
                   commit;
        
                   // output an error-page
                   char[16] tmp = void;
                   auto code = Integer.itoa(tmp, status.code);

                   output ("<HTML>\n<HEAD>\n<TITLE>Error ")
                          (code)
                          (" ")
                          (reason)
                          ("</TITLE>\n<BODY>\n<H2>HTTP Error: ")
                          (code)
                          (" ")
                          (reason)                       
                          ("</H2>\n")
                          (message ? message : "")
                          ("\n</BODY>\n</HTML>\n");
									 flush;
                   }
        }
}



