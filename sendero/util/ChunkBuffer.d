
module sendero.util.ChainBuffer;

import tango.io.Buffer;
import tango.net.SocketConduit;
import tango.net.Socket;

version(Debug)
	import tango.io.Stdout;
/*******************************************************************

	ChunkedBuffer
	Almost standard buffer implementation except that it is dispensed
	via a freelist, also, it features a chaining mechanism
	so that buffers don't have to be resized, rather, new 
	buffers are simply pulled off of the freelist and written
	to.

*******************************************************************/
const int BUFSIZE = (8*1024);

class ChainBuffer : Buffer
{
	private ChainBuffer next;
	private ChainBuffer currentout;
	private ChainBuffer currentin;
	private bool usingSocket;
	public


	/*****************************************************************

		Iterate through all chained buffers, draining the contents into
		the sink. 

	*****************************************************************/	
	final uint drainAll()
	{
		uint total;
		uint len;
		version(Debug)              
			Stdout.formatln("next buffer is {:x}", &currentout);
		while (len == 0 && currentout)
		{
			currentout.output(this.sink);
			
			version(Debug)
				Stdout.formatln("using next buffer to drain");

			if (currentout.readable() < 1)
				break;
			total += currentout.adrain();
			len = currentout.readable();
			currentout = currentout.next;
		}
		if (currentout.readable() == 0)
			currentout = this;
		return total;
	}

	/********************************************************************

		Iterate through all chained buffers, reading from the input stream
		into as many buffers as it will fill. 
		A return of -1 is there is no data to be read. 
		a return of -2 is a socket error. 	
	*********************************************************************/
	final int fillAll(InputStream istream)
	{
		if (capacity < 1)
			return 0;
		int read;
		uint total = currentin.afill(istream);
		switch(total)
		{
			case 0:
				return -2;
			case -1:
				return -1;
			default:
				;
		}
		uint lim = limit;
		uint cap = capacity;

		while(lim == cap)
		{
			version(Debug)
				Stdout.formatln("Creating New ChainBuffer");
			ChainBuffer cb = New(usingSocket);
			read = cb.afill(istream);
			switch (read)
			{
				case 0:
					return -2;
				case -1:
					return total;
				default:
					;
			}
			total += read;
			lim = cb.limit;
			cap = cb.capacity;
			currentin.next = cb;
			currentin = cb;
		}
		return total;
	}

	/*******************************************************************

		Pull a free ChainBuffer off of the freelist or allocate a new
		one if none exist

	*******************************************************************/
	static ChainBuffer New(bool issock=true)
	{
		ChainBuffer cb;
		synchronized(mtx)
		{
			if (freelist)
			{
					cb = freelist;
					freelist = cb.next;
			}
			else
				cb = new ChainBuffer(issock);
		}
		cb.next = null;
		return cb;
	}

	/*******************************************************************

		Place this chunk and all of its children back onto the freelist
	
	********************************************************************/
	static void Delete(ChainBuffer cb)
	{
		cb.reset();
		ChainBuffer nxt = cb;
		ChainBuffer last;
		while(nxt)
		{
			last = nxt;
			nxt.reset();
			nxt = nxt.next;
		}

		synchronized(mtx)
		{
			last.next = freelist;
			freelist = cb;
		}
	}

	this(bool issock = true)
	{
		usingSocket = issock;
		currentout = currentin = this;
		super(BUFSIZE);
	}
	private static ChainBuffer freelist;
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

	int afill (InputStream src)
	{
		if (src is null)
			return IConduit.Eof;

		if (readable is 0)
			clear();
		else 
			if (writable is 0)
				return 0;

		if (usingSocket)
		{
			Socket sock = (cast(SocketConduit) src).socket();
			return write (&sock.receive);
		}
		return super.write(&src.read);
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

	/********************************************************************

		reset, re-initializes the currentin and currentout as well as 
	  clears the buffer

	********************************************************************/
	void reset()
	{
		currentin = this;
		currentout = this;
		clear();
	}	
}


version (UnitTest)
{
	import tango.io.FileConduit;
	import tango.io.Stdout;
	void main()
	{
		auto from = new FileConduit ("test.in");
		auto buf = ChainBuffer.New(false);

		int ttl = buf.fillAll(from);
		Stdout.formatln("read {} bytes", ttl);

		auto to = new FileConduit("test.out", FileConduit.WriteCreate);
		buf.output(to);
		ttl = buf.drainAll();
		Stdout.formatln("wrote {} bytes", ttl);
		ChainBuffer.Delete(buf);
		to.close();
		
		// take 2 

		from = new FileConduit ("test.in");
		buf = ChainBuffer.New(false);

		ttl = buf.fillAll(from);
		Stdout.formatln("read {} bytes", ttl);
		from.seek(0);
		ttl = buf.fillAll(from);
		Stdout.formatln("read {} bytes", ttl);

		to = new FileConduit("test.out", FileConduit.WriteCreate);
		buf.output(to);
		ttl = buf.drainAll();
		Stdout.formatln("wrote {} bytes", ttl);
		ChainBuffer.Delete(buf);
	}
}
