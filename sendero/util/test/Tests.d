module sendero.util.Tests;

import tango.io.Console;
import tango.io.Stdout;
import sendero.util.AsyncServer;

int handle_data(char[] buf)
{
  Stdout.formatln("Received buffer {}",buf);
	return 0;
}

int handle_error(char[] buf)
{
	Stdout.formatln("Error in receiving data - {}",buf);
	return 0;
}

void main()
{
  AsyncServer s = new AsyncServer();

	s.setEventCallback(&handle_data);
	s.setErrorCallback(&handle_error);
	s.run();

	s.shutdown();
}

