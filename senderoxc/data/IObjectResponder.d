module senderoxc.data.IObjectResponder;

public import decorated_d.core.Decoration;

interface IField
{
	void writeDecl(IPrint wr);
	void writeIsModifiedExpr(void delegate(char[]) wr);
	bool hasGetter();
	bool hasSetter();
	char[] name();
	char[] privateName();
	char[] dtype();
}

interface IObjectBuilder
{
	void addField(IField, out uint setterIdx);
}

interface IObjectResponder
{
	void writeCheckModifier(char[] delegate(FieldDeclaration));
}