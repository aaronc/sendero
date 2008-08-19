module senderoxc.data.IObjectResponder;

public import decorated_d.core.Decoration;

interface IField
{
	void writeDecl(IPrint wr);
	void writeIsModifiedExpr(void delegate(char[]) wr);
	bool hasGetter();
	bool hasSetter();
	char[] name();
}

interface IObjectBuilder
{
	void addField(IField);
}

interface IObjectResponder
{
	void writeCheckModifier(char[] delegate(FieldDeclaration));
}