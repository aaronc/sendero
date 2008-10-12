module senderoxc.Live;

import senderoxc.Process;

import sendero.http.Request;

class SenderoXCLive
{
	this(char[] conffile, char[] confname)
	{
		this.conffile = conffile;
		this.confname = confname;
	}
	
	char[] conffile, confname;
	
	void delegate(Req) getSenderoAppMain()
	{
		return null;
	}
}