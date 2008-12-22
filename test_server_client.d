module test_server_client;

//import tango.net.http.HttpClient;
//import tango.net.http.HttpConst;
import tango.net.http.HttpGet;
import tango.io.Stdout;

int main(char[][] args)
{
	while(1) {
		auto page = new HttpGet("http://127.0.0.1:8081");
		auto content = cast(char[])page.read;
		assert(content == "Hello Sendero Server World!\r\n", content);
	}
	return 0;
}

