module sendero.server.io.model.ICachedBuffer;

interface ICachedBuffer
{
	void release();
	void[] getBuffer();
}

interface ICachedBufferProvider
{
	ICachedBuffer get();
}
