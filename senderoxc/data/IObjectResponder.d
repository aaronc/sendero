module senderoxc.data.IObjectResponder;

public import decorated_d.core.Decoration;
public import dbi.model.BindType;

interface IField
{
	void writeDecl(IPrint wr);
	char[] isModifiedExpr();
	bool hasGetter();
	bool hasSetter();
	bool httpSet();
	char[] name();
	//char[] privateName();
	char[] fieldAccessor();
	char[] colname();
	char[] dtype();
	BindType bindType();
}

interface IMapping
{
	char[] isModifiedExpr();
	char[] colname();
	char[] fieldAccessor();
	char[] dtype();
	BindType bindType();
	bool isPrimaryKey();
}

interface IObjectBuilder
{
	void addField(IField, out uint setterIdx);
}

enum InheritanceType { None, SingleTable, MultiTable };

interface IObjectResponder
{
	char[] classname();
	IField[] fields();
	size_t bindableFieldCount();
	IObjectResponder parent();
	IObjectResponder[char[]] children();
	InheritanceType inheritance();
	void writeCheckModifier(char[] delegate(FieldDeclaration));
}