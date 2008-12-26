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

interface IMapping
{
	char[] isModifiedExpr();
	char[] colname();
	char[] fieldAccessor();
	char[] dtype();
	bool isPrimaryKey();
}

interface IObjectBuilder
{
	void addField(IField, out uint setterIdx);
}

interface IObjectResponder
{
	char[] classname();
	IField[] fields();
	IObjectResponder parent();
	IObjectResponder[char[]] children();
	void writeCheckModifier(char[] delegate(FieldDeclaration));
}