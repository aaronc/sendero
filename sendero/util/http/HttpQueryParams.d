/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
       
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module sendero.util.http.HttpQueryParams;

public  import  tango.net.http.HttpParams;
private import  tango.net.http.HttpTokens;

/******************************************************************************

        Maintains a set of HTTP query parameters. This is a specialization
        of HttpParams, with support for parameters without a '=' separator

******************************************************************************/

class HttpQueryParams : HttpParams
{
        /**********************************************************************

                overridable method to handle the case where a token does
                not have a separator. Apparently, this can happen in HTTP 
                usage

        **********************************************************************/

        protected bool handleMissingSeparator (char[] s, inout HttpToken element)
        {
                element.name = s;
                element.value = null;
                return true;
        }
}
