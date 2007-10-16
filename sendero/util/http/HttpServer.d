/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.util.http.HttpServer;

public  import  tango.net.InternetAddress;

private import  tango.util.log.Logger;

private import  tango.net.ServerSocket;

private import  tango.io.model.IConduit;

private import  mango.net.util.AbstractServer;

private import  mango.net.util.model.IRunnable;

private import  sendero.util.http.HttpThread,
                sendero.util.http.HttpBridge,
                sendero.util.http.ServiceBridge,            
                sendero.util.http.ServiceProvider;

/******************************************************************************
        
        Extends the AbstractServer to glue all the Http support together.
        One should subclass this to provide a secure (https) server.

******************************************************************************/

class HttpServer : AbstractServer
{
        private ServiceProvider provider;

        /**********************************************************************

                Construct this server with the requisite attribites. The
                ServiceProvider represents a service handler, the binding addr
                is the local address we'll be listening on, and 'threads'
                represents the number of thread to initiate.

        **********************************************************************/

        this (ServiceProvider provider, InternetAddress bind, int threads, Logger log = null)
        {
                this (provider, bind, threads, 50, log);
        }

        /**********************************************************************

                Construct this server with the requisite attribites. The
                ServiceProvider represents a service handler, the binding addr
                is the local address we'll be listening on, and 'threads'
                represents the number of thread to initiate. Backlog is
                the number of "simultaneous" connection requests that a
                socket layer will buffer on our behalf.

        **********************************************************************/

        this (ServiceProvider provider, InternetAddress bind, int threads, int backlog, Logger log = null)
        {
                if (log is null)
                    log = Log.getLogger ("http.server");
                super (bind, threads, backlog, log);
                this.provider = provider;
        }

        /**********************************************************************

                Return the protocol in use.

        **********************************************************************/

        char[] getProtocol()
        {
                return "http";
        }

        /**********************************************************************

                Return a text string identifying this server

        **********************************************************************/

        override char[] toUtf8()
        {
                return getProtocol~"::"~provider.toUtf8;
        }

        /**********************************************************************

                Create a ServerSocket instance. Secure implementations
                would provide a SecureSocketServer, or something along
                those lines.

        **********************************************************************/

        override ServerSocket createSocket (InternetAddress bind, int backlog, bool reuse=false)
        {
                return new ServerSocket (bind, backlog, reuse);
        }

        /**********************************************************************

                Create a ServerThread instance. This can be overridden to 
                create other thread-types, perhaps with additional thread-
                level data attached.

        **********************************************************************/

        override IRunnable createThread (ServerSocket socket)
        {
                return new HttpThread (this, socket);
        }

        /**********************************************************************

                Factory method for servicing a request. We just toss the
                request across our bridge, for the ServiceProvider to handle.

        **********************************************************************/

        override void service (IRunnable st, IConduit conduit)
        {
                HttpThread      thread;
                ServiceBridge   bridge;

                // we know what this is because we created it (above)
                thread = cast(HttpThread) st;

                // extract thread-local HttpBridge
                if ((bridge = thread.getBridge) is null)
                   {
                   // create a new instance if it's the first service 
                   // request on this particular thread
                   bridge = new HttpBridge (this, provider, thread);
                   thread.setBridge (bridge);
                   }

                // process request
                bridge.cross (conduit);
        }
}

