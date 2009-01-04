module sendero.server.http.HttpResponder;

public import tango.io.model.IConduit;
version(Tango_0_99_7) import tango.io.FileConduit, tango.io.Conduit;
else import tango.io.device.File, tango.io.device.Conduit;

import tango.net.http.HttpConst;
import Integer = tango.text.convert.Integer;
import Timestamp = tango.text.convert.TimeStamp;
import Text = tango.text.Util;
import tango.time.Clock;

import sendero.server.model.ITcpServiceProvider;
import sendero.server.io.CachedBuffer;
import sendero.server.io.GzipStream;

class HttpResponder : OutputStream
{
	this()
	{
		
	}
	
	void[] headerBuf_;
	char[] mimeType_;
	
	/**
	 * Sets HTTP response status.
	 * If no status is set, defaults to 200 OK.
	 */
	void setStatus(HttpStatus status)
	{
		headerBuf_ = "HTTP/1.x ";
		headerBuf_ ~= Integer.toString(status.code);
		headerBuf_ ~= " ";
		headerBuf_ ~= status.name;
		headerBuf_ ~= "\r\n";
	}
	
	void setHeader(char[] field, char[] value)
	{
		headerBuf_ ~= field;
		headerBuf_ ~= ": ";
		headerBuf_ ~= value;
		headerBuf_ ~= "\r\n";
	}
	
	void setContentType(char[] mimeType)
	{
		mimeType_ = mimeType;
		headerBuf_ ~= "Content-Type: ";
		headerBuf_ ~= mimeType;
		headerBuf_ ~= "\r\n";
	}
	
	void sendHeaders()
	{
		
	}
	
	TcpResponse sendContent(char[] mimeType, void[][] data...)
	{
		char[64] tmp;
		auto res = new TcpResponse;
		setStatus(HttpResponses.OK);
		headerBuf_ ~= "Server: Sendero\r\n";
		HttpResponder.setContentType(mimeType);
		headerBuf_ ~= "Date: ";
		headerBuf_ ~= Timestamp.format(tmp, Clock.now);
		headerBuf_ ~= "\r\n";
		headerBuf_ ~= "Connection: keep-alive\r\n";
		size_t len;
		foreach(d; data) len += d.length;
		headerBuf_ ~= "Content-Length: ";
		headerBuf_ ~= Integer.toString(len);
		headerBuf_ ~= "\r\n\r\n";
		res.data ~= headerBuf_;
		res.data ~= data;
		return res;
	}
	
	enum SendFlags { Default = 0x0, ChunkedHeadersSet = 0x1, EndResponse = 0x2 };
	
	
	void sendData(void[][] data...)
	{
		
	}
	
	/**
	 * Auto compression determines compression based on MIME type.
	 * The following MIME types will be compressed automatically if the
	 * client supports it and if compression is set to CompressionFlag.Auto:
	 * 	text/*
	 * 	application/javascript
	 * 	application/x-javascript
	 * 	application/ecmascript
	 * 	application/xhtml+xml
	 * 	application/json
	 * 	application/atom+xml
	 * 	application/xslt+xml
	 * 	application/mathml+xml
	 * 	application/rss+xml
	 * 
	 */
	enum CompressionFlag { Auto, None, Gzip, Deflate };
	
/+	OutputStream getOutputStream(char[] mimeType, CompressionFlag compression)
	{
		
	}+/
	
	static private CompressionFlag getCompressionFromMimeType(char[] mimeType)
	{
		auto paramIdx = Text.locate(mimeType, ';');
		mimeType = Text.trim(mimeType[0..paramIdx]);
		
		CompressionFlag compressionRes;
		if(mimeType.length >= 5 && mimeType[0..4] == "text/")
			compressionRes = CompressionFlag.Auto;
		else if(mimeType.length > 12 && mimeType[0..11] == "application/"){
			switch(mimeType[12..$])
			{
			case "javascript":
			case "x-javascript":
			case "ecmascript":
			case "xhtml+xml":
			case "json":
			case "atom+xml":
			case "xslt+xml":
			case "mathml+xml":
			case "rss+xml":
				compressionRes = compressionRes.Auto;
				break;
			default:
				compressionRes = compressionRes.None;
				break;
			}
		}
		else compressionRes = compressionRes.None;
		return compressionRes;
	}
	
	void sendFile(char[] mimeType, char[] filename, bool cache, CompressionFlag compression)
	{
		auto compressionRes = compression;
		if(compression == CompressionFlag.Auto) {
			compressionRes = getCompressionFromMimeType(mimeType);
		}
		
		if(cache) {
			if(compressionRes == CompressionFlag.None) {
				
			}
			else {
				
			}
		}
		else {
			if(compressionRes == CompressionFlag.None) {
				version(Windows) {
					auto file = new FileConduit(filename);
					copy(file);
				}
				else {
					// use sendfile					
				}
			}
			else {
				auto file = new FileConduit(filename);
				auto gzip = new GzipOutput(this);
				gzip.copy(file);
			}
		}
	}

	private WriteBuffer buffer_;
	private size_t idx_;
	
	private enum State { HeadersUncommitted, ChunkedTransfer, ContentLengthTransfer, Done }
	private State state_;

version(Tango_0_99_7) { }
else {
	long seek (long offset, Anchor anchor = Anchor.Begin)
	{
		throw new IOException("HttpOutputStream doesn't support seeking", __FILE__, __LINE__);
	}
}
	
	IConduit conduit ()
	{
		return null;
	}
	
	void close()
	{
		assert(state_ != State.Done);
		if(state_ == State.HeadersUncommitted) {
			// Set Content-Length = buffer_.buffer.length
			// Send headers
			// Send chunk
		}
		else if(state_ == State.ChunkedTransfer){
			assert(state_ == State.ChunkedTransfer);
			size_t writeable = buffer_.buffer.length - idx_;
			if(writeable < 5) {
				auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
				buffer_.buffer[5..6] = "\r\n";
				// Send chunk buffer_.buffer[4 - chunkSize.length ..idx_];
				// TODO get small buffer
				auto temp = new void[5];
				temp = "\r\n0\r\n";
				// Send temp;
			}
			else {
				auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
				buffer_.buffer[5..6] = "\r\n";
				buffer_.buffer[idx_..idx_+5] = "\r\n0\r\n";
				// Send chunk buffer_.buffer[4 - chunkSize.length .. $];
			}
		}
		state_ = State.Done;
	}
	
	size_t write(void[] src)
	{
		size_t written = 0;
		
		void getNewBuffer()
		{
			
		}
		
		void initChunkBuffer()
		{
			// get new buffer;
			idx_ = 6;
		}
		
		void writeChunkData(void[] data)
		{
			size_t writeable = buffer_.buffer.length - idx_;
			if(writeable == 0) initChunkBuffer;
			size_t src_len = data.length;
			if(writeable < src_len) {
				buffer_.buffer[idx_..$-2] = data[0..writeable];
				written += writeable;
				buffer_.buffer[$-2..$] = "\r\n";
				auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
				buffer_.buffer[5..6] = "\r\n";
				// Send chunk buffer_.buffer[4 - chunkSize.length .. $];
				initChunkBuffer;
				writeChunkData(data[writeable..$]);
			}
			else {
				buffer_.buffer[idx_ .. idx_ + src_len] = src[0..$];
				idx_ += src_len;
				written += src_len;
			}
		}
		
		void writeContentLengthData(void[] data)
		{
			size_t writeable = buffer_.buffer.length - idx_;
			size_t src_len = data.length;
			if(writeable < src_len) {
				buffer_.buffer[idx_ .. $] = data[0..writeable];
				written += writeable;
				getNewBuffer;
				writeContentLengthData(data);
			}
			else {
				buffer_.buffer[idx_ .. idx_ + src_len] = src[0..$];
				idx_ += src_len;
				written += src_len;
			}
		}
		
		assert(state_ != State.Done);
		
		if(state_ == State.HeadersUncommitted) {
			size_t writeable = buffer_.buffer.length - idx_;
			size_t src_len = src.length;
			if(writeable < src_len) {
				buffer_.buffer[idx_..$-2] = src[0..writeable];
				written += writeable;
				buffer_.buffer[$-2..$] = "\r\n";
				// Set Transfer-Encoding: chunked
				// Append first first chunk size to headers
				// Send headers
				// Send first chunk
				state_ = State.ChunkedTransfer;
				initChunkBuffer;
				writeChunkData(src[writeable..$]);
			}
			else {
				written += src_len;
				buffer_.buffer[idx_ .. idx_ + src_len] = src[0..$];
				idx_ += src_len;
			}
		}
		else if(state_ == State.ChunkedTransfer) {
			writeChunkData(src);
		}
		else if(state_ == State.ContentLengthTransfer) {
			writeContentLengthData(src);
		}
		
		return written;
	}
	
	OutputStream copy (InputStream src)
	{
		Conduit.transfer (src, this);
		return this;
		//assert(false, "Not implemented");
	}
	
	OutputStream flush ()
	{
		return this;
	}
	
	OutputStream output ()
	{
		return null;
	}
}