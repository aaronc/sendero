module senderoxc.data.IObjectResponder;

public import decorated_d.core.Decoration;

interface IField
{
	void writeDecl(IPrint wr);
	char[] isModifiedExpr();
	bool hasGetter();
	bool hasSetter();
	char[] name();
	char[] privateName();
	char[] colname();
	char[] dtype();
}

interface IObjectBuilder
{
	void addField(IField, out uint setterIdx);
}

interface IObjectResponder
{
	IField[] fields();
	void writeCheckModifier(char[] delegate(FieldDeclaration));
}