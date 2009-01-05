module sendero.server.http.HttpResponder;

public import tango.io.model.IConduit;
version(Tango_0_99_7) import tango.io.FileConduit, tango.io.Conduit;
else import tango.io.device.File, tango.io.device.Conduit;

import tango.net.http.HttpConst;
import Integer = tango.text.convert.Integer;
import Timestamp = tango.text.convert.TimeStamp;
import Text = tango.text.Util;
import tango.time.Clock;
public import tango.net.http.HttpCookies;
import tango.net.http.HttpHeaders;
import tango.io.Buffer;

import sendero.server.model.ITcpServiceProvider;
import sendero.server.io.CachedBuffer;
import sendero.server.io.GzipStream;

import tango.util.log.Log;
Logger log;
static this()
{
	log = Log.lookup("sendero.server.http.HttpResponder");
}

class HttpResponder : OutputStream
{
	this()
	{
		headers_ = new HttpHeaders(new Buffer(1024));
		cookies_ = new HttpCookies(headers_);
		requestHeaders_ = new HttpHeaders(new Buffer(4096));
	}
	
	private HttpHeaders headers_;
	private HttpCookies cookies_;
	private HttpStatus status_;
	
	private void[] headerBuf_;
	private char[] mimeType_;
	
	void setCompletionPort(ITcpCompletionPort completionPort)
	{
		completionPort_ = completionPort;
	}
	private ITcpCompletionPort completionPort_;
	private TcpResponse syncResponse_;
	
	
	
	private CachedBuffer buffer_;
	private size_t idx_;
	
	private enum WriteState { Headers, Data, Done };
	private enum TransferState { Unknown, Chunked, ContentLength };
	private enum State { BeforeHeaders, BeforeData,
		HeadersUncommitted, ChunkedTransfer,
		ContentLengthTransfer, Done };
	private State state_;
	private WriteState writeState_;
	private TransferState transferState_;

	
	private int flags_;
	private enum Flags { KeepAlive = 0x1 };
	
	protected HttpHeaders requestHeaders_;
	
	void handleHeader(char[] field, char[] value)
	{
		requestHeaders_.add(HttpHeaderName(field), value);
		switch(field)
		{
		case "KEEP-ALIVE":
			flags_ |= Flags.KeepAlive;
			break;
		default:
			break;
		}
	}
	
	/**
	 * Sets HTTP response status.
	 * If no status is set, defaults to 200 OK.
	 */
	void setStatus(HttpStatus status)
	{
		assert(writeState_ == WriteState.Headers);
		status_ = status;
	}
	
	void setHeader(HttpHeaderName field, char[] value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.add(field,value);
	}
	
	void setHeader(char[] field, char[] value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.add(HttpHeaderName(field),value);
	}
	
	void setHeader(HttpHeaderName field, int value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.addInt(field, value);
	}
	
	void setHeader(char[] field, int value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.addInt(HttpHeaderName(field), value);
	}
	
	void setHeader(HttpHeaderName field, Time value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.addDate (field, value);
	}
	
	void setHeader(char[] field, Time value)
	{
		assert(writeState_ == WriteState.Headers);
		headers_.addDate(HttpHeaderName(field), value);
	}
	
	void setContentType(char[] mimeType)
	{
		assert(writeState_ == WriteState.Headers);
		mimeType_ = mimeType;
		headers_.add(HttpHeader.ContentType,mimeType_);
	}
	
	void setContentLength(size_t contentLength)
	{
		assert(writeState_ == WriteState.Headers);
		assert(transferState_ == TransferState.Unknown);
		headers_.addInt(HttpHeader.ContentLength,contentLength);
		transferState_ = TransferState.ContentLength;
	}
	
	void setChunked()
	{
		assert(writeState_ == WriteState.Headers);
		assert(transferState_ == TransferState.Unknown);
		headers_.add(HttpHeader.TransferEncoding,"chunked");
		transferState_ = TransferState.Chunked;
	}
	
	void setCookie(char[] name, char[] value)
	{
		assert(writeState_ == WriteState.Headers);
		cookies_.add(new Cookie(name, value));
	}
	
	void setCookie(Cookie cookie)
	{
		assert(writeState_ == WriteState.Headers);
		cookies_.add(cookie);
	}
	
	private void finishHeaders()
	{
		headerBuf_ = "HTTP/1.x ";
		headerBuf_ ~= Integer.toString(status_.code);
		headerBuf_ ~= " ";
		headerBuf_ ~= status_.name;
		headerBuf_ ~= "\r\n";
		/+char[64] tmp;
		headerBuf_ ~= "Server: Sendero\r\n";
		headerBuf_ ~= "Date: ";
		headerBuf_ ~= Timestamp.format(tmp, Clock.now);
		headerBuf_ ~= "\r\n";
		headerBuf_ ~= "Connection: keep-alive\r\n";
		headerBuf_ ~= "\r\n";+/
		headers_.add(HttpHeader.Server, "Sendero");
		headers_.addDate(HttpHeader.Date, Clock.now);
		if(flags_ & Flags.KeepAlive)
			headers_.add(HttpHeader.Connection, "keep-alive");
		auto buf = headers_.getOutputBuffer;
		debug log.trace("Headers Output: {}", cast(char[])buf.slice);
		headers_.produce((void[] val) {headerBuf_ ~= val;}, HttpConst.Eol);
		headerBuf_ ~= "\r\n";
		writeState_ = WriteState.Data;
	}
	
	void sendHeaders()
	{
		finishHeaders;
	}
	
	void sendContent(char[] mimeType, void[][] data...)
	{
		assert(writeState_ == WriteState.Headers);
		auto res = new TcpResponse;
		setStatus(HttpResponses.OK);
		setContentType(mimeType);
		size_t len;
		foreach(d; data) len += d.length;
		setContentLength(len);
		finishHeaders;
		res.data ~= headerBuf_;
		res.data ~= data;
		syncResponse_ = res;
		writeState_ = WriteState.Done;		
	}
	
	TcpResponse getSyncResponse()
	{
		assert(writeState_ == WriteState.Done);
		return syncResponse_;
	}
	
	enum SendFlags { Default = 0x0, ChunkedHeadersSet = 0x1, EndResponse = 0x2 };
	
	
	private void sendWriteBuffer(bool haveMoreData = false, size_t start = 0, size_t end = size_t.max)
	{
		void initChunkBuffer()
		{
			// get new buffer;
			idx_ = 6;
		}
	}
		
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
		assert(writeState_ == WriteState.Headers || writeState_ == WriteState.Data);
		if(writeState_ == WriteState.Headers) {
			assert(transferState_ == TransferState.Unknown);
			// Set Content-Length = buffer_.buffer.length
			// Send headers
			// Send chunk
			// Create sync response
		}
		else if(transferState_ == TransferState.Chunked){
			if(writeState_ == WriteState.Data) {
				size_t writeable = buffer_.buffer.length - idx_;
				if(writeable < 5) {
					auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
					buffer_.buffer[5..6] = "\r\n";
					// TODO get small buffer
					sendWriteBuffer(false, 4 - chunkSize.length, idx_);
					auto temp = new void[5];
					temp = "\r\n0\r\n";
					assert(false, "Not implemented");
					// TODO Send temp;
				}
				else {
					auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
					buffer_.buffer[5..6] = "\r\n";
					buffer_.buffer[idx_..idx_+5] = "\r\n0\r\n";
					// Send chunk buffer_.buffer[4 - chunkSize.length .. $];
					sendWriteBuffer(false, 4 - chunkSize.length, idx_);
				}
			}
			else if(writeState_ == WriteState.Headers) {
			//Automatically revert to Content-Length transfer state
				setContentLength(idx_);
				sendHeaders;
				sendWriteBuffer(false, 0, idx_);
			}
			else assert(false, "Uexpected state");
		}
		state_ = State.Done;
	}
	
	size_t write(void[] src)
	{
		size_t written = 0;
		
		void writeChunkData(void[] data)
		{
			size_t writeable = buffer_.buffer.length - idx_;
			size_t src_len = data.length;
			if(writeable <= src_len) {
				buffer_.buffer[idx_..$-2] = data[0..writeable];
				written += writeable;
				buffer_.buffer[$-2..$] = "\r\n";
				auto chunkSize = Integer.format(cast(char[])buffer_.buffer[0..4],buffer_.buffer.length,"x");
				buffer_.buffer[5..6] = "\r\n";
				sendWriteBuffer(true, 4 - chunkSize.length, buffer_.buffer.length);
				if(writeable < src_len) writeChunkData(data[writeable..$]);
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
			if(writeable <= src_len) {
				buffer_.buffer[idx_ .. $] = data[0..writeable];
				written += writeable;
				sendWriteBuffer(true);
				if(writeable < src_len) writeContentLengthData(data);
			}
			else {
				buffer_.buffer[idx_ .. idx_ + src_len] = src[0..$];
				idx_ += src_len;
				written += src_len;
			}
		}
		
		assert(writeState_ == WriteState.Headers || writeState_ == WriteState.Data);
		
		if(writeState_ == WriteState.Headers) {
			assert(transferState_ == TransferState.Unknown);
			size_t writeable = buffer_.buffer.length - idx_;
			size_t src_len = src.length;
			if(writeable <= src_len) {
				buffer_.buffer[idx_..$-2] = src[0..writeable];
				written += writeable;
				buffer_.buffer[$-2..$] = "\r\n";
				setChunked;
				headerBuf_ ~= Integer.toString(buffer_.buffer.length - 2);
				headerBuf_ ~= "\r\n";
				sendHeaders;
				sendWriteBuffer(true);
				if(writeable < src_len) writeChunkData(src[writeable..$]);
			}
			else {
				written += src_len;
				buffer_.buffer[idx_ .. idx_ + src_len] = src[0..$];
				idx_ += src_len;
			}
		}
		else if(transferState_ == TransferState.Chunked) {
			assert(writeState_ == WriteState.Data);
			writeChunkData(src);
		}
		else if(state_ == State.ContentLengthTransfer) {
			assert(writeState_ == WriteState.Data);
			writeContentLengthData(src);
		}
		
		return written;
	}
	
	OutputStream copy (InputStream src)
	{
		Conduit.transfer (src, this);
		return this;
		//assert(false, "Not implemented");
	/+	
		if(state_ == State.HeadersUncommitted) {
			auto len = src.read(buffer_.buffer[idx_ .. $]);
			idx_ += len;
			buffer_.buffer[$-2 .. $] = "\r\n";
			// Set Transfer-Encoding: chunked
			// Append first first chunk size to headers
			// Send headers
			// Send first chunk
			state_ = State.ChunkedTransfer;
			//initChunkBuffer;
		}
		else if(state_ == State.ChunkedTransfer) {
			writeChunkData(src);
		}
		else if(state_ == State.ContentLengthTransfer) {
			writeContentLengthData(src);
		}
		
		auto len = src.read(buffer_.buffer[idx_ .. $]);
		//idx_ +/
		
		/+
		 byte[8192] tmp;
         size_t     done;

         while (max)
               {
               auto len = max;
               if (len > tmp.length)
                   len = tmp.length;

               if ((len = src.read(tmp[0 .. len])) is Eof)
                    max = 0;
               else
                  {
                  max -= len;
                  done += len;
                  auto p = tmp.ptr;
                  for (auto j=0; len > 0; len -= j, p += j)
                       if ((j = dst.write (p[0 .. len])) is Eof)
                            dst.conduit.error ("Conduit.copy :: Eof while writing to: "~
                                                dst.conduit.toString);
                  }
               }

         return done;+/

	}
	
	OutputStream flush ()
	{
		return this;
	}
	
	OutputStream output ()
	{
		return null;
	}
	
	void reset()
	{
		requestHeaders_.reset;
		headers_.reset;
		writeState_ = WriteState.Headers;
		transferState_ = TransferState.Unknown;
	}
}