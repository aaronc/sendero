module scripts.create_project;

import tango.io.Stdout;
import tango.text.convert.Layout;
import tango.io.stream.FileStream;
import tango.io.Path;

static this()
{
	layout = new Layout!(char);
}

Layout!(char) layout;

void createFolder_(char[] name)
{
	if(!exists(name)) {
		Stdout.formatln("Creating folder {}", name);
		createFolder(name);
	}
}

void createFile_(char[] name)
{
	if(!exists(name)) {
		Stdout.formatln("Creating file {}", name);
		createFile(name);
	}
}

void writeFile_(char[] templname)(char[] outputname, ...)
{
	if(!exists(outputname)) {
		Stdout.formatln("Creating file {}", outputname);
		auto output = new FileOutput(outputname);
		layout((char[] data) { return output.write(data);}
			, _arguments, _argptr, import(templname));
		output.flush.close;
	}
}

int create_project(char[][] args)
{
	if(args.length < 2) {
		Stdout.formatln("Please specify a project name");
		return -1;
	}
	
	auto projName = args[1];
	
	Stdout.formatln("Creating project {}", projName);
	
	createFolder_(projName);
	createFolder_(projName ~ "/ctlr");
	createFolder_(projName ~ "/model");
	createFolder_("public");
	createFolder_("public/css");
	createFolder_("public/images");
	createFolder_("public/js");	
	createFolder_("view");
	createFolder_("test");
	
	createFile_("dsss.conf");
	createFile_("sendero.conf");
	createFile_("senderoxc.conf");
	writeFile_!("Rakefile.template")("Rakefile", projName, projName, projName, projName);
	writeFile_!("Session.d.template")(projName ~ "/Session.d", projName);
	writeFile_!("_app.d.template")(projName ~ "_app.d", projName, projName, projName);
	writeFile_!("Main.d.template")(projName ~ "/Main.d", projName, projName, projName);
	//writeFile_!("DB.d.template")(projName ~ "/DB.d", projName);
	
	
	return 0;
}

int main(char[][] args)
{
	return create_project(args);
}

