module sendero.http.IRenderable;

public import sendero.http.ContentType;

interface IRenderable : IStream
{
	char[] contentType();
}

interface IStream
{
	void render(void delegate(void[]));
}