module sendero.server.io.model.IBufferProvider;

class SimpleBuffer
{
	void[] buffer;
}

interface IBufferProvider
{
	SimpleBuffer get();
}