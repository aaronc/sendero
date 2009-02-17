module sendero.server.io.model.ICachedBuffer;

interface ICachedBuffer
{
	void release();
	void[] getBuffer();
	ICachedBuffer getNext();
	void setNext(ICachedBuffer);
}