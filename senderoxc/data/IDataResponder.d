module senderoxc.data.IDataResponder;

public import decorated_d.core.Decoration;
public import senderoxc.data.mapper.IMapper;
public import senderoxc.data.IInterface;
public import senderoxc.data.Schema;
public import senderoxc.data.IValidationResponder;

interface IDataResponder : IInterfaceWriter
{
	char[] classname();
	void addValidation(IValidationResponder);
	IMapper mapper();
	Schema schema();
	IObjectResponder obj();
	DeclarationInfo decl();
}