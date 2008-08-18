module senderoxc.data.mapper.IMapper;

public import senderoxc.data.IInterface;
public import decorated_d.core.Decoration;
public import senderoxc.data.Schema;
public import senderoxc.util.CodeGen;

interface IMapperResponder
{
	void write(IPrint);
}

interface IMapper : IInterfaceWriter
{
	Schema schema();
	char[][] getPrimaryKeyFields();
}