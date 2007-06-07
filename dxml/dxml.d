import tango.io.Stdout;
import tango.io.FileConduit;
import tango.io.FileScan;
import tango.io.File;
import tango.io.Buffer;
import tango.io.protocol.Writer;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;
import Integer = tango.text.convert.Integer;

/**
 *
 * Authors: Aaron Craelius
 * 
 * Basic Usage:
 * <!--TemplateName-->
 * <%!function(prototype)%><%!/%>
 * <%=output%>
 * <%code%>
 * <_gettext text_>
 */

class CharScanner
{
	Logger log;
	this(char[] str)
	{
		log = Log.getLogger("DXML");
		str_ = str;
		len_ = str.length;
		log.trace("Length:" ~ Integer.toUtf8(len_));
	}
	
	char[] str_;
	ulong len_;
	ulong i = 0;
	bool opCall(inout char c)
	{
		if(i >= len_) {
			return false;
		}

		c = str_[i];
		++i;
		return true;
	}

	bool getStr(inout char[] str, uint len)
	{
		if(lookStr(str, len)) {
			i += len;
			return true;
		}
		return false;
	}

	bool lookStr(inout char[] str, uint len)
	{
		if(i + len >= len_)
			return false;
		str = str_[i .. i + len];
		return true;
	}

	char[] output_;
	char[] output() { return output_; }
	void opCatAssign(char[] str)
	{
		output_ ~= str;
	}

	void opCatAssign(char c)
	{
		output_ ~= c;
	}

	bool look(inout char c, int x)
	{
		ulong y = i + x;
		if(y >= len_) {
			return false;
		}

		c = str_[y];
		return true;
	}
}

class DXmlProcessor
{
	Logger log;
	this()
	{
		log = Log.getLogger("DXML");
	}

	void process(char[] moduleName)
	{
		char[][char[]] templates;
		char[][char[]] layouts;
		char[] viewModuleDir = "./" ~ moduleName ~ "/views";
		auto scan = new FileScan;
		scan(viewModuleDir, ".html");

		void readFile(char[] filename, CharScanner s)
		{
			void noHeader()
			{
				Stdout("File does not contain a valid view header of the form <!--ViewName-->.");
			}
			
			char[] init;
			if(!s.getStr(init, 4) || init != "<!--") {
				noHeader();
				return;
			}
			bool isLayout = false;
			char[] layoutCheck;
			if(s.lookStr(layoutCheck, 7)) {
				if(layoutCheck == "Layout:") {
					s.getStr(layoutCheck, 7);
					isLayout = true;
				}	
			}
			char c;
			char[] name;
			while( s (c) ) {
				if(c != '-') {
					name ~= c;
					continue;
				}
				char[] endTag;
				if(!s.getStr(endTag, 2) || endTag != "->") {
					noHeader();
					return;
				}
				break;
			}

			
			if(!isLayout) {
				DXmlReader.readTemplate(s);
				templates[name] ~= "//FILE " ~ filename ~ "\n" ~ s.output ~ "\n\n";
			}
			else {
				log.trace("Reading Layout");
				DXmlReader.readLayout(s);
				char[] layout = "//FILE " ~ filename ~ "\n";
				layout ~= "class " ~ name ~ "Layout : ViewLayout\n";
				layout ~= "{\n";
				layout ~= s.output;
				layout ~= "}\n";
				layouts[name] = layout;
			}
		}

        Stdout.formatln ("\n{0} Files", scan.files.length);
        foreach (file; scan.files) {
			Stdout.formatln ("{0}", file);
			auto fc = new FileConduit(file, FileConduit.ReadExisting);
			auto content = new char[fc.length];
			auto bytesRead = fc.read (content);
			auto s = new CharScanner(content);
			readFile(file.toUtf8(), s);
		}

		char[] viewModule;

		viewModule ~= "module " ~ moduleName ~ ".views;\n\n";
		viewModule ~= "public import webf.view;\n\n";
		
		foreach(templateName, templateContent; templates)
		{
			viewModule ~= "template " ~ templateName ~ "()\n{\n\n";
			viewModule ~= templateContent;
			viewModule ~= "\n}\n\n";
		}

		foreach(layoutName, layout; layouts)
		{
			viewModule ~= layout ~ "\n";
		}

		//fc.close();
		char[] viewModuleFile = viewModuleDir ~ ".d";
		auto f = new File(viewModuleFile);
		f.write(viewModule);
		Stdout("View Module File Written to " ~ viewModuleFile ~ "\n");
	}

	private class DXmlReader
	{
		static Logger log;
		
		static this()
		{
			log = Log.getLogger("DXML");
		}

		static private void readLayout(CharScanner s)
		{
			s ~= "char[] render()\n{\n";
			s ~= "\tchar[] output;\n";
			readFunction(s);
			s ~= "\treturn output;\n}\n";
		}

		static private void readTemplate(CharScanner s)
		{
			void finish()
			{
				s ~= "\tpage.content = output;\n\treturn page;\n}";
			}

			char c;
			while(s.look(c, 0))
			{
				switch(c)
				{
					case '<':
						if(!s.look(c, 1))
							return;
						if(c != '%') {
							s(c); s(c);
							s ~= "<" ~ c;
							break;
						}
						if(!s.look(c, 2))
							return;
						if(c != '!') {
							s(c); s(c); s(c);
							s ~= "<%" ~ c;
							break;
						}
						s(c); s(c); s(c);
						while(1) {
							s.look(c, 0);
							if(c != '%') {
								s(c);
								s ~= c;
								continue;
							}
							s.look(c, 1);
							if(c != '>') {
								s(c); s(c);
								s ~= "%" ~ c;
								continue;
							}
							s(c); s(c);
							s ~= "\n{\n\tauto page = new ViewPage(layout);\n\tchar[] output;\n";
							break;
						}
						readFunction(s);
						finish();
						break;
					default:
						s (c);
						s ~= c;
					
				}
			}
		}
		
		static private void readFunction(CharScanner s)
		{
			char c;

			void doCode(CharScanner s)
			{
				bool needSemicolon = false;
				
				void finish()
				{
					if(needSemicolon)
						s ~= ";";
					s ~= "\n";
				}

				void doInstanceVariable()
				{
					char[] var;
					s~= "if(";
					while(s.look(c, 0) && c != '.' && c != '[' & c != '%')
					{
						s(c);
						var ~= c;
					}
					s ~= var ~ " !is null)\n";
					s ~= "\t\toutput ~= " ~ var;
					while(s (c) && c != '%')
						s ~= c;
					s ~= ";\n";
					s(c);
					if(c != '>')
						log.warn("Code block closed incorrectly near instance variable " ~ var);
				}
				
				s ~= '\t';

				if(!s.look(c, 0))
					return;
				switch(c)
				{
					case '=':
						//Do Output
						if(s.look(c, 1) && c == '@') {
							s(c); s(c);
							return doInstanceVariable();
						}
						s ~= "output ~= ";
						needSemicolon = true;
						s(c);
						break;
					case '@':
						//Do Link
						//TODO
						break;
					default:
						break;
				}
				
				while(s.look(c, 0))
				{					
					switch(c)
					{
						case '%':
							{
								if(!s.look(c, 1)) {
									finish();
									return;
								}
								if(c == '>') {
									//Finish
									s(c); s(c);
									finish();
									return;
								}
								//Send '%' to output
								s(c);
								s ~= c;								
							}
							break;
						default:
							s(c);
							s ~= c;
							break;
					};
				}
				finish();
			}


			void doGettext(CharScanner s)
			{
				void finish()
				{
					s ~= "\");\n";
				}
				
				s ~= "\toutput ~= gettext(\"";
				while(s.look(c, 0))
				{
					switch(c)
					{
						case '_':
							{
								if(!s.look(c, 1)) {
									s (c);
									s ~= c;
									finish();
									return;
								}
								if(c == '>') {
									//Finish
									s(c); s(c);
									finish();
									return;
								}
								//Send '<' to output
								s(c);
								s ~= c;								
							}
							break;
						default:
							s(c);
							s ~= c;
							break;
					};
				}
				finish();
			}

			void doEcho(CharScanner s)
			{
				void start()
				{
					s ~= "\toutput ~= \"";
				}

				void finish()
				{
					s ~= "\";\n";
				}

				start();				
				while(s.look(c, 0))
				{
					switch(c)
					{
						case '<':
							{
								if(!s.look(c, 1)) {
									s(c);
									s ~= c;
									finish();
									return;
								}
								switch(c)
								{
									case '%':
										//Finish
										finish();
										return;
										break;
									case '_':
										//Finish
										finish();
										return;
										break;
									case '!':
										//Comment block handling
										char[] str;
										if(!s.lookStr(str, 4) || str != "<!--") {
											s(c);
											s ~= c;
											break;
										}
										s(c); s(c); s(c); s(c);
										finish();
										s ~= "\t//<!--";
										while( s (c) )
										{
											if(c == '-')
											{
												s.lookStr(str, 2);
												if(str == "->") {
													s(c); s(c);
													s ~= "-->\n";
													break;
												}
											}
											s ~= c;
										}
										start();
										break;
									default:
										//Send '<' to output
										s(c);
										s ~= c;
										break;
								}
							}
							break;
						case '\"', '\\':
							s ~= "\\";
							s(c);
							s ~= c;
							break;
						case '\n':
							s (c);
							s ~= "\\n";
							break;
						case '\r':
							s (c);
							//For now just ignore the carriage return
							break;
						default:
							s(c);
							s ~= c;
							break;
					};
				}
				finish();
			}
			

			while(s.look(c, 0))
			{
				switch(c)
				{
					case '<':
						{
							if(!s.look(c, 1))
								return;
							switch(c)
							{
								case '%':
									s (c); s(c);
									if(!s.look(c, 0))
										return;
									if(c == '!')
										//End of function;
										return;														
									log.trace("Do Code");
									doCode(s);
									break;
								case '_':
									s (c); s(c);
									log.trace("Do Gettext");
									doGettext(s);
									break;
								default:
									log.trace("Do Output1");
									doEcho(s);
									break;
							};
						}
						break;
					case '\n', '\r':
						s (c);
						//TODO output newline?
						break;
					default:
						log.trace("Do Output2");
						doEcho(s);
						break;
				}
			}
		}
	}
}

int main(char[][] args)
{
	auto log = Log.getLogger("DXML");
	log.setLevel(Logger.Level.Warn);
	log.addAppender(new ConsoleAppender());

	if(args.length != 2)
	{
		Stdout("Invalid usage.");
	}

	auto processor = new DXmlProcessor;

	processor.process(args[1]);

	return 0;
}