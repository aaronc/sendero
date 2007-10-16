/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.util.http.ServiceProvider;

private import  sendero.util.http.HttpRequest,
                sendero.util.http.HttpResponse,
                sendero.util.http.ServiceBridge;

/******************************************************************************

        Contract to be fulfilled by all HTTP provider instances.

******************************************************************************/

interface ServiceProvider
{
        /**********************************************************************

                Concrete provider must provide the service handler

        **********************************************************************/

        void service (HttpRequest request, HttpResponse response);

        /**********************************************************************

                Concrete provider must provide a request factory

        **********************************************************************/

        HttpRequest createRequest (ServiceBridge bridge);

        /**********************************************************************

                Concrete provider must provide a response factory

        **********************************************************************/

        HttpResponse createResponse (ServiceBridge bridge);

        /**********************************************************************

                Concrete provider must provide an identifying text string
              
        **********************************************************************/

        char[] toUtf8 ();
}

