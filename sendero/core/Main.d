module sendero.core.Main;

import sendero.http.Request;

version(SenderoFCGI) {
	import sendero.backends.FCGI;
	
	int senderoMain(AppMain, Session)(char[][] args)
	{
		auto fcgiRunner = new FCGIRunner!(Session, Session.RequestT)(&AppMain.main);
		fcgiRunner.run(args);
		return 0;
	}
	
} else {
	
	import sendero.server.SimpleTest;
	
	int senderoMain(AppMain, Session)(char[][] args)
	{
		run(&AppMain.main);
		return 0;
	}
}