module sendero.server.io.IO;


IStreamReader
{
	void[] nextChunk();
	void releaseChunk(void[]);
}

struct ChainedBuffer {
	void[] buffer;
	ChainedBuffer* next;
}

class ReadHost
{
	
}

class StreamReader : IStreamReader
{
	Fiber handleFiber;
	
	void doReading()
	{
		while(/*have some new data*/) {
			if(handleFiber is null)
				handleFiber = new Fiber(&doHandling);
			handleFiber.call;
		}
	}
	
	void doHandling()
	{
		handler.sendData(this);
	}
	
	ChainedBuffer* head;
	ChainedBuffer* tail;
	ChainedBuffer* cur;
	
	void[] nextChunk()
	{
		if(cur.next is null) {
			Fiber.yield;
			if(cur.next is null) return null;
		}
		cur = cur.next;
		return cur.buffer;
		//if have chunk, advance, return chunk,
		//else if waiting for chunk pause fiber, and wait to be called again 
	}
	
	void releaseChunk(void[] buf)
	{
		if(buf.ptr == head.buffer.ptr) {
			// release(head)
			head = head.next;
		}
		
		// TODO if released chunk not is head
	}
}

alias bool delegate(void delegate(void[])) InputStream;

// HTTP Parser asks to read more until buffer is full or end of content
// Call from http handler for next buffer, fills buffer and then returns