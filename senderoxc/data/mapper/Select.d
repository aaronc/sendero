module senderoxc.data.mapper.Select;

class SelectResponder : IMapperResponder
{
	this(IMapper m)
	{
		m.addMethod(new FunctionDeclaration("select", "ResultSet"));
		this.mapper = m;
	}
	
	private IMapper mapper;
	
	void write(IPrint)
	{
		wr.fln("ResultSet!({})(char[][] fields, char[] sql)");
		wr("{").nl;
		wr.indent;
		wr.dedent;
		wr("}\n");
		wr("\n");
	}
}