module sendero.io.Buffer;

import sendero.server.io.CachedBuffer;
import sendero.core.Thread;

const size_t SmallBufferSize = 2048;
const size_t StandardBufferSize = 32768;
const size_t LargeBufferSize = 65536;
const size_t VeryLargeBufferSize = 131072;

class SmallBufferPool : ICachedBufferProvider
{
	CachedBuffer get()
	{
		
	}
}