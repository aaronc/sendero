module test_server_client;

import tango.net.http.HttpGet;
import tango.io.Stdout;
import tango.time.StopWatch;

int main(char[][] args)
{
	StopWatch timer;
	
	timer.start;
	uint i = 0;
	while(i < 10000) {
		auto page = new HttpGet("http://127.0.0.1:8081");
		auto content = cast(char[])page.read;
		assert(content == "Hello Sendero Server World!\r\n", content);
		++i;
		page.close;
	}
	auto t = timer.stop;
	Stdout.formatln("{} requests handled in {} seconds",i,t);
	Stdout.formatln("{} requests per second",i/t);
	
	
	timer.start;
	i = 0;
	while(1) {
		try
		{
			auto page = new HttpGet("http://127.0.0.1:8081");
			auto content = cast(char[])page.read;
			assert(content == "Hello Sendero Server World!\r\n", content);
			++i;
		}
		catch(Exception ex)
		{
			Stdout(ex.toString).newline;
			break;
		}
	}
	t = timer.stop;
	Stdout.formatln("{} requests handled in {} seconds",i,t);
	Stdout.formatln("{} requests per second",i/t);
	return 0;
}

