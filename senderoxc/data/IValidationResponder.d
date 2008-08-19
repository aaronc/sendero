module senderoxc.data.IValidationResponder;

public import decorated_d.core.Decoration;

interface IValidationResponder
{
	void atStaticThis(IDeclarationWriter wr);
	void atBody(IDeclarationWriter wr);
	void atOnValidate(IDeclarationWriter wr);
}