module sendero.server.io.ChunkStream;

class ChunkOutput : OutputFilter
{
        private OutputBuffer output;

        /***********************************************************************

                Use a buffer belonging to our sibling, if one is available

        ***********************************************************************/

        this (OutputStream stream)
        {
                super (output = BufferOutput.create(stream));
        }

        /***********************************************************************

                Write a chunk to the output, prefixed and postfixed in a 
                manner consistent with the HTTP chunked transfer coding

        ***********************************************************************/

        final override size_t write (void[] src)
        {
                char[8] tmp = void;
                
                output.append (Integer.format (tmp, src.length, "x"))
                      .append ("\r\n")
                      .append (src)
                      .append ("\r\n");
                return src.length;
        }

        /***********************************************************************

                Write a zero length chunk, trailing headers and a terminating 
                blank line

        ***********************************************************************/

        final void terminate (void delegate(OutputBuffer) headers = null)
        {
                output.append ("0\r\n");
                if (headers)
                    headers (output);
                output.append ("\r\n");
        }
}