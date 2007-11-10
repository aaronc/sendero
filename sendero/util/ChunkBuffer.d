
module sendero.util.ChunkBuffer;

import tango.io.Buffer;
import tango.net.SocketConduit;
import tango.net.Socket;
/*******************************************************************

	ChunkedBuffer
	Almost standard buffer implementation except that it is dispensed
	via a freelist, also, it features a chaining mechanism
	so that buffers don't have to be resized, rather, new 
	buffers are simply pulled off of the freelist and written
	to.

*******************************************************************/

class ChunkBuffer : Buffer
{
	private ChunkBuffer next;

	public


	/*****************************************************************

		Iterate through all chained buffers, draining the contents into
		the sink. 

	*****************************************************************/	
	final uint drainAll()
	{
		uint total;
		uint lim;
		ChunkBuffer nxt = this;
		while (lim == 0 && nxt)
		{
			total += nxt.adrain();
			lim = nxt.limit;
			nxt = nxt.next;
		}
	}

	/********************************************************************

		Iterate through all chained buffers, reading from the input stream
		into as many buffers as it will fill. 
	
	*********************************************************************/
	final uint fillAll(InputStream istream)
	{
		if (capacity < 1)
			return 0;
		uint total = afill(istream);
		uint lim = limit;
		uint cap = capacity;

		while(lim == cap)
		{
			ChunkBuffer cb = New();
			total += cb.afill(istream);
			lim = cb.limit;
			cap = cb.capacity;
		}
		return total;
	}

	/*******************************************************************

		Pull a free ChunkBuffer off of the freelist or allocate a new
		one if none exist

	*******************************************************************/
	static ChunkBuffer New()
	{
		ChunkBuffer cb;
		synchronized(mtx)
		{
			if (freelist)
			{
					cb = freelist;
					freelist = cb.next;
			}
			else
				cb = new ChunkBuffer;
		}
		cb.next = null;
		return cb;
	}

	/*******************************************************************

		Place this chunk and all of its children back onto the freelist
	
	********************************************************************/
	static void Delete(ChunkBuffer cb)
	{
		cb.clear();
		ChunkBuffer nxt = cb;
		while(nxt)
		{
			nxt.clear();
			nxt = nxt.next;
		}
		synchronized(mtx)
		{
			nxt.next = freelist;
			freelist = cb;
		}
	}

	private static FastBuffer freelist;
	private static Object mtx;
	static this()
	{
		mtx = new Object;
	}
	/***********************************************************************

		Drain buffer content to the specific conduit

		Returns:
		Returns the number of bytes written

		Remarks:
		Write as much of the buffer that the associated conduit
		can consume. The conduit is not obliged to consume all 
		content, so some may remain within the buffer.

		This differs from the original drain in that it doesn't throw
		an exception on eof. This is oriented towards async/nonblocking 
		operations, so a premature eof is to be expected, this will 
		simply tell the event reader to wait for another read event.

	 ***********************************************************************/

	uint adrain ()
	{
		auto dst = sink;
		assert (dst);

		return read(&dst.write);
	}

	/***********************************************************************

		Fill buffer from the specific conduit

		Returns:
		Returns the number of bytes read, or Conduit.Eof

		Remarks:
		Try to _fill the available buffer with content from the 
		specified conduit. We try to read as much as possible 
		by clearing the buffer when all current content has been 
		eaten. If there is no space available, nothing will be 
		read.

	 ***********************************************************************/

	uint afill (InputStream src)
	{
		if (src is null)
			return IConduit.Eof;

		if (readable is 0)
			clear();
		else 
			if (writable is 0)
				return 0;
		Socket sock = (cast(SocketConduit) src).socket();
		return write (&sock.receive);
	}

	/***********************************************************************

		Write into this buffer

		Params:
		dg = the callback to provide buffer access to

		Returns:
		Returns whatever the delegate returns.

		Remarks:
		Exposes the raw data buffer at the current _write position, 
		The delegate is provided with a void[] representing space
		available within the buffer at the current _write position.

		The delegate should return the appropriate number of bytes 
		if it writes valid content, or IConduit.Eof on error.

	 ***********************************************************************/

	uint write (int delegate (void[], SocketFlags) dg, 
			SocketFlags flags = SocketFlags.NONE)
	{
		int count = dg (data [extent..dimension], flags);

		if (count > 0) 
		{
			extent += count;
			assert (extent <= dimension);
		}
		return count;
	}  
}
