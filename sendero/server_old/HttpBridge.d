/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.server.HttpBridge;

private import  tango.net.Socket;

private import  tango.io.model.IConduit;
private import  tango.net.SocketConduit;
private import  mango.net.util.model.IServer;

private import  sendero.server.HttpThread;

private import  sendero.util.http.HttpRequest,
                sendero.util.http.HttpResponse,
								sendero.util.http.HttpProvider,
                sendero.util.http.ServiceBridge,
                sendero.util.http.ServiceProvider;

import tango.core.Thread;
import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;

/******************************************************************************

        Bridges between an ServiceProvider and an IServer, and contains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of HttpBridge (one per 
        server-thread).

        Any additional thread-specific data should probably be contained
        within this class, since it is reachable from almost everywhere.

******************************************************************************/

class HttpBridge : ServiceBridge
{
        private ServiceProvider provider;
			
        private HttpThread      thread;
        private HttpRequest     request;
        private HttpResponse    response;
      
				private Logger          logger;
				private Sprint!(char)   sprint;
	
        /**********************************************************************

                Construct a bridge with the requisite attributes. We create
                the per-thread request/response pair here, and maintain them 
                for the lifetime of the server.

        **********************************************************************/

        this (HttpProvider provider, HttpThread thread)
        {
                this.thread = thread;
                this.provider = provider;

                request = provider.createRequest (this);
                response = provider.createResponse (this);
					
								sprint = new Sprint!(char);
								logger = Log.getLogger("HttpBridge");
				}

				IServer getServer() { return null;}
        /**********************************************************************

                Bridge the divide between IServer and ServiceProvider instances.
                Note that there is one instance of this class per thread.

                Note also that this is probably the right place to implement 
                keep-alive support if that were ever to happen, although the
                implementation should itself be in a subclass.

        **********************************************************************/

        void cross (IConduit conduit)
        {
                // bind our input & output instance to this conduit
								logger.info(sprint("Thread: {0} crossing conduit {1}",
														Thread.getThis().name(), (cast(SocketConduit)conduit).fileHandle()));
								

                request.setConduit (conduit);
                response.setConduit (conduit);

								//there will be no closing of sockets
                //scope (exit)
                //       conduit.detach;

                // reset the (probably overridden) input and output
                request.reset();
                response.reset();

                // first, extract HTTP headers from input
                request.readHeaders ();

                // pass request off to the provider. It is the provider's 
                // responsibility to flush the output!
                //(cast(SocketConduit) conduit).socket().blocking(true);
								provider.service (request, response);
        }
}
