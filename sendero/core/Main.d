module sendero.core.Main;

import sendero.core.Config;
import sendero.http.Request;

version(SenderoFCGI) {
	import sendero.backends.FCGI;
	import tango.io.FileSystem;
	
	int senderoMain(AppMain, Session)(char[][] args)
	{
		FileSystem.setDirectory("..");
		version(Production) SenderoConfig.load("production");
		else SenderoConfig.load("dev");
		auto fcgiRunner = new FCGIRunner!(Session, Session.RequestT)(&AppMain.main);
		fcgiRunner.run(args);
		return 0;
	}
	
} else {
	
	import sendero.server.SimpleTest;
	
	int senderoMain(AppMain, Session)(char[][] args)
	{
		version(Production) SenderoConfig.load("production");
		else SenderoConfig.load("dev");
		run(&AppMain.main);
		return 0;
	}
}
