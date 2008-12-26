module sendero.server.runtime.StackTrace;

import tango.core.Runtime;
version(Tango_0_99_7) import tango.io.FileConduit;
else import tango.io.device.FileConduit;
import tango.text.stream.LineIterator;
import tango.core.Array;
import Int = tango.text.convert.Integer;

debug import tango.io.Stdout;

version(linux) extern(C)
{
	int backtrace(void **buffer, int size);
	char **backtrace_symbols(void **buffer, int size);
	void backtrace_symbols_fd(void **buffer, int size, int fd);
}

class Symbol
{
	this(char[] name, void* code, ptrdiff_t size = 0)
	{
		this.code = code;
		this.name = name;
		this.size = size;
		//debug Stdout.formatln("Adding symbol {} fron {} to {}", name, code, code + size);
	}
	
	void* code;
	char[] name;
	ptrdiff_t size;
	
	static Symbol[] symbols;
	
	static char[][] splitLine(char[] line)
	{
		char[][] parts;
		uint i = 0; uint len = line.length;
		for(;i < len;++i) {
			if(line[i] != ' ' && line[i] != '\t') break;
			++i;
		}
		uint curStart = i;
		for(;i < len;++i) {
			switch(line[i])
			{
			case ' ':
			case '\t':
				if(curStart != i) parts ~= line[curStart .. i];
				curStart = i + 1;
				break;
			default:break;
			}
		}
		if(curStart < len) parts ~= line[curStart..$];
		return parts;
	}
	
	/**
	 * Loads symbols from the results of objdump <exename> -t
	 * on the executable file in Linux.
	 * 
	 */
	static void loadObjDumpSymbols(char[] filename)
	{
		try
		{
			auto lines = new LineIterator!(char)(new FileConduit(filename));
			foreach(line; lines)
			{
				auto parts = splitLine(line);
				if(parts.length < 6 || parts[3] != ".text") continue;
				symbols ~= new Symbol(parts[5].dup,
					cast(void*)Int.parse(parts[0],16),
					cast(ptrdiff_t)Int.parse(parts[4],16)
				);
			}
			sort(symbols,(Symbol s1, Symbol s2){
				return s1.code < s2.code;
			});
			
		}
		catch(Exception ex)
		{
			throw new Exception("Symbol.loadDumpObjSymbols failed on filename " ~ filename, ex);
		}
	}
	
	static Symbol find(void* code)
	{
		size_t	beg = 0,
				end = symbols.length,
				mid = end/2;
		
		while(beg < end)
		{
			if(code < symbols[mid].code)
				end = mid;
			else
				beg = mid;
			mid = beg + (end - beg) /2;
			if(code >= symbols[mid].code && code <= symbols[mid].code + symbols[mid].size)
				return symbols[mid];
			if(end - mid == 1) break;
		}
		//return symbols[mid];
		return null;
	}
}

class StackTrace : Exception.TraceInfo
{	
	static this()
	{
		Runtime.traceHandler = &traceHandler;
	}
	
	static Exception.TraceInfo traceHandler(void* ptr = null)
	{
		return new StackTrace;
	}
	
	private this()
	{
		doTrace;
	}
	
	static StackTrace get()
	{
		return new StackTrace;
	}
	
	private void doTrace()
	{
		version(linux) {
			void* trace[64];
			int trace_size = 0;
	
			trace_size = backtrace(trace.ptr, 16);
			
			trace_ = trace[0 .. trace_size].dup;
		}
	}
	
	private void*[] trace_;
	private Symbol[] symbols_;
	
	private void findSymbols()
	{
		symbols_.length = trace_.length;
		foreach(i, code; trace_)
		{
			symbols_[i] = Symbol.find(code);
		}
	}
	
	int opApply( int delegate( inout char[] val) dg)
	{
		findSymbols;
		
		int res = 0;
		foreach(uint i, void* code;trace_)
		{
			char[] val = Int.toString(cast(uint)code,"x");
			if(i < symbols_.length && symbols_[i] !is null)
				val ~= "\t" ~ symbols_[i].name;
			if((res = dg(val)) != 0)
				break;
		}
		
		return res;
	}
	
    char[] toString()
    {
    	char[] res = "-- Stack Trace --\r\n";
    	foreach(val; this)
    	{
    		res ~= val ~ "\r\n";
    	}
    	return res;
    }
}
/+
char[][] stackBacktrace()
{
	void* trace[32];
	char **messages = null;
	int i, trace_size = 0;

	trace_size = backtrace(trace.ptr, 16);
	messages = backtrace_symbols(trace.ptr, trace_size);
	Stdout.formatln("Backtrace");
	  for (i=0; i<trace_size; ++i)
		//printf("[bt] %s\n", messages[i]);
		  Stdout.formatln("[bt] {} {}", messages[i], trace[i]);
	  
	  
	  return null;
}+/