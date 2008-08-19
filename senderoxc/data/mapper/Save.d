module senderoxc.data.mapper.Save;

import senderoxc.data.mapper.IMapper;

class SaveResponder(MapperT = IMapper) : IMapperResponder
{
	this(MapperT m)
	{
		m.addMethod(new FunctionDeclaration("save", "bool"));
		this.mapper = mapper;
	}
	protected MapperT mapper;
	
	void write(IPrint wr)
	{
		wr.fln("bool save()");
		wr("{").nl;
		wr.indent;
		wr.dedent;
		wr("}").nl;
		wr.nl;
	}
}