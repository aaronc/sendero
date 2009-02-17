module senderoxc.data.mapper.Bind;

class BindResponder : IMapperResponder
{
	this(IMapper m)
	{
		m.addMethod(new FunctionDeclaration("createBinder", "Binder"));
		this.mapper = m;
	}
	
	private IMapper mapper;
	
	void write(IPrint)
	{
		
	}
}