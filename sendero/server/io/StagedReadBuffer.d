module sendero.server.io.StagedReadBuffer;

class StagedReadBuffer
{
	this(void[] buffer)
	{
		buffer_ = buffer;
		index_ = 0;
		released_ = false;
	}
	
	private void[] buffer_;
	private size_t index_;
	private bool released_;
	private StagedReadBuffer next_; 
	
	size_t writeable() {
		return buffer_.length - index_;
	}
	
	size_t readable() {
		return index_;
	}
	
	void[] getWritable()
	{
		assert(!released_);
		return buffer_[index_ .. $];
	}
	
	void[] getReadable() {
		assert(!released_);
		return buffer_[0 .. index_];
	}
	
	void[] getContent() {
		return buffer_;
	}
	
	void setNextBuffer(StagedReadBuffer buf) {
		next_ = buf;
	}
	
	StagedReadBuffer next() {
		return next_;
	}
	
	void advanceWritten(size_t n)
	{
		assert(!released_);
		index_ += n;
	}
	
	void release()
	{
		released_ = true;
	}
}