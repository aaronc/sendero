module sendero.view.SenderoTemplate;

import sendero.view.SenderoTemplateInternals;
import sendero.vm.ExecutionContext;
//alias AbstractSenderoTemplateContext!(ExecutionContext, AbstractSenderoTemplateContext) SenderoTemplateContext;
//alias AbstractSenderoTemplate!(ExecutionContext, SenderoTemplateContext) SenderoTemplate;

class SenderoTemplateContext : AbstractSenderoTemplateContext!(ExecutionContext, SenderoTemplateContext, SenderoTemplate)
{
	this(SenderoTemplate tmpl)
	{
		super(tmpl);
	}
	
	char[] render()
	{
		return tmpl.render(cast(SenderoTemplateContext)this);
	}
}

class SenderoTemplate : AbstractSenderoTemplate!(SenderoTemplateContext, SenderoTemplate)
{
	
}

version(Unittest)
{
	import tango.io.Stdout;
	import tango.group.time;
	
	static class Name
	{
		uint somenumber;
		char[] first;
		char[] last;
		DateTime date;
	}
	
	
unittest
{
	/+auto bigtable = "<table>"
		"<tr d:for='$row in $table'>"
		"<td d:for='$c in $row'>_{$c}</td>"
		"</tr>"
		"</table>";+/
	auto bigtable = "<table xmlns:d='http://dsource.org/projects/sendero'>"
		"<d:for each='$row in $table'><tr>"
		"<d:for each='$c in $row'><td>_{$c}</td></d:for>"
		"</tr></d:for>"
		"</table>";
	
	auto tmpl = SenderoTemplate.compile(bigtable);
	auto inst = new SenderoTemplateContext(tmpl);
	
	ubyte[][] table;
	for(int i = 0; i < 10; ++i)
	{
		ubyte[] row;
		for(int j = 1; j <= 10; ++j)
		{
			row ~= j;
		}
		table ~= row;
	}
	inst["table"] = table;
	
	StopWatch btWatch;
	btWatch.start;
	for(uint i = 0; i < 2; ++i) {
		Stdout(inst.render);
	}
	auto btTime = btWatch.stop;
	Stdout.formatln("btTime:{}", btTime);
	
	auto derived = SenderoTemplate.get("derivedtemplate.xml");
	derived["name"] = "bob";
	Stdout(derived.render).newline;
	
	auto derived2 = SenderoTemplate.get("derived2.xml");
	derived2["name"] = "alice";
	Stdout(derived2.render).newline;
	
	Name[] names;
	auto n = new Name;
	n.first = "John";
	n.last = "Doe";
	n.somenumber = 1234567;
	n.date.date.year = 1976;
	n.date.date.month = 3;
	n.date.date.day = 17;
	names ~= n;
	n = new Name;
	n.first = "Jackie";
	n.last = "Smith";
	n.somenumber = 7654321;
	n.date.date.year = 1942;
	n.date.date.month = 10;
	n.date.date.day = 14;
	names ~= n;
	n = new Name;
	n.first = "Joe";
	n.last = "Schmoe";
	n.somenumber = 7654321;
	n.date.date.year = 1967;
	n.date.date.month = 3;
	n.date.date.day = 3;
	names ~= n;
	n = new Name;
	n.first = "Pete";
	n.last = "This Is Neat";
	n.somenumber = 7654321;
	n.date.date.year = 1967;
	n.date.date.month = 3;
	n.date.date.day = 3;
	names ~= n;
	
	auto complex = SenderoTemplate.get("test/complex.xml");
	complex["person"] = n;
	complex["names"] = names;
	Stdout(complex.render).newline;
}
}