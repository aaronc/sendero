module sendero.server.io.GzipStream;

private import tango.io.compress.ZlibStream;
private import tango.io.model.IConduit : InputStream, OutputStream;

version (Windows) {
	pragma (lib, "zlib.lib");
} 

class GzipInput : ZlibInput
{
	this(InputStream stream)
	{
		super(stream, 16);
	}
}

class GzipOutput : ZlibOutput
{
	this(OutputStream stream, Level level = Level.Normal)
	{
		super(stream, level, 16);
	}
}