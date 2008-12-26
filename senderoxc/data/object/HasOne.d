module senderoxc.data.object.HasOne;

class HasOneCtxt : IStandaloneDecoratorContext
{	
	this(DataResponder resp)
	{
		this.resp = resp;
	}
	DataResponder resp;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl) {
			if(decorator.params.length > 1 &&
					decorator.params[0].type == VarT.String &&
					decorator.params[1].type == VarT.String) {
				auto type = decorator.params[0].string_;
				auto name = decorator.params[1].string_;
				resp.addGetter(Getter(type, name));
				
				auto col = ColumnInfo(name ~ "_id", BindType.UInt);
				resp.schema.addColumn(col);
				
				auto idx = resp.addSetter(Setter(type, name, name ~ ".id_"));
				return new HasOneResponder(idx, type, name);
			}
		}
		
		return null;
	}
}

class HasOne : IField, IMapping
{
	this(uint index, char[] type, char[] name)
	{
		super(index, type, name);
	}
	
	void writeDecl(IPrint wr)
	{
		wr("public " ~ type ~ " " ~ name ~ "() {return " ~ name ~ "_;}\n");
		wr("public void " ~  name ~ "(" ~ type ~ " val) {");
		wr(`assert(val.id != 0, "HasOne of type ` ~ type ~ ` must be saved before being set";` ~ "\n");
		wr("__touched__[" ~ Integer.toString(index) ~ "] = true; " ~ name ~ "_ = val;");
		wr("}\n");
		wr("private HasOne!(" ~ type ~ ") " ~ name ~ "_;\n\n");
	}
}