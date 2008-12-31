module senderoxc.data.object.HasOne;

import decorated_d.core.Decoration;

import senderoxc.data.object.Field;
import senderoxc.data.IDataResponder;
import senderoxc.data.IObjectResponder;

import Integer = tango.text.convert.Integer;

class HasOneCtxt : IStandaloneDecoratorContext
{	
	this(IObjectBuilder objBuilder, IDataResponder resp)
	{
		this.resp = resp;
		this.objBuilder = objBuilder;
	}
	
	IObjectBuilder objBuilder;
	IDataResponder resp;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl) {
			if(decorator.params.length > 1 &&
					decorator.params[0].type == VarT.String &&
					decorator.params[1].type == VarT.String) {
				auto type = decorator.params[0].string_;
				auto name = decorator.params[1].string_;
				auto field = new HasOneField(type,name);
				
				auto col = Schema.prepColumnInfo(FieldType("UInt","uint", BindType.UInt));
				col.name = name;
				resp.schema.addColumn(col);
				
				resp.addMethod(new FunctionDeclaration(name, type));
				resp.addMethod(new FunctionDeclaration(name, "void", [FunctionDeclaration.Param(type)]));
				
				objBuilder.addField(field, field.index_);
			}
		}
		
		return null;
	}
}

class HasOneField : IField, IMapping
{
	this(char[] type, char[] name)
	{
		type_ = type;
		name_ = name;
	}
	
	private char[] type_;
	private char[] name_;
	private uint index_;
	
	uint index() { return index_; }
	
	void writeDecl(IPrint wr)
	{
		wr.fln("public {} {}(){{return {}.inst;}",dtype, name, privateName);
		wr.fln("public void {}({} val) {{",name,dtype);
		wr.fln(`assert(val.id != 0, "HasOne of type {} must be saved before being set");`,dtype);
		wr.fln("__touched__[{0}] = true; {1}.inst = val; {1}.id = val.id;",index,privateName);
		wr.fln("}");
		wr.fln("private HasOne!({}) {};",dtype,privateName).newline;
	}
	
	char[] isModifiedExpr()
	{
		return "__touched__[" ~ Integer.toString(index)  ~ 
		"] || " ~ privateName ~ ".isModified";
	}
	bool hasGetter() { return true; }
	bool hasSetter() { return true; }
	bool httpSet() { return false; }
	bool isPrimaryKey() { return false; }
	char[] name() { return name_; }
	char[] fieldAccessor() { return privateName ~ ".id"; }
	char[] privateName() { return name ~ "_"; }
	char[] colname() { return name ~ "_id"; }
	char[] dtype() { return type_; }
	BindType bindType() { return BindType.UInt; }
}