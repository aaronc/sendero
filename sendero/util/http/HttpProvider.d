/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.util.http.HttpProvider;

private import  sendero.util.http.HttpRequest,
                sendero.util.http.HttpResponse,
                sendero.util.http.ServiceBridge,
                sendero.util.http.ServiceProvider;

/******************************************************************************

        Bridges between an ServiceProvider and an IServer, and maintains a set of
        data specific to each thread. There is only one instance of server
        and provider, but multiple live instances of ServiceBridge (there
        is one per server-thread).

        Any additional thread-specific data should probably be maintained
        via this interface.

******************************************************************************/

class HttpProvider : ServiceProvider
{
        /**********************************************************************

                Concrete provider must provide the service handler

        **********************************************************************/

        abstract void service (HttpRequest request, HttpResponse response);

        /**********************************************************************

                ServiceProvider interface to create a request instance

        **********************************************************************/

        HttpRequest createRequest (ServiceBridge bridge)
        {
                return new HttpRequest (bridge);
        }

        /**********************************************************************

                ServiceProvider interface to create a response instance

        **********************************************************************/

        HttpResponse createResponse (ServiceBridge bridge)
        {
                return new HttpResponse (bridge);
        }

        /**********************************************************************

                Return the name of this provider for identification purposes.

        **********************************************************************/

        override char[] toUtf8()
        {
                return "raw";
        }
}

