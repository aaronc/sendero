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
				
				Field.Attributes attr;
				
				attr.getter = true;
				attr.setter = true;
				attr.primaryKey = false;
				attr.setterProtection = Protection.Public;
				
				foreach(dec; decorator.decorators)
				{
					switch(dec.name)
					{
					case "no_setter": attr.setter = false; break;
					case "privateSetter": attr.setterProtection = Protection.Private; break;
					case "protectedSetter": attr.setterProtection = Protection.Protected; break;
					case "packageSetter": attr.setterProtection = Protection.Package; break;
					default:
						break;
					}
				}
				
				auto field = new HasOneField(type,name,attr);
				
				auto col = Schema.prepColumnInfo(FieldType("UInt","uint", BindType.UInt));
				col.name = name;
				resp.schema.addColumn(col);
				
				if(attr.getter) {
					auto getter = new FunctionDeclaration(name, type);
					resp.addMethod(getter);
				}
				if(attr.setter) {
					auto setter = new FunctionDeclaration(name, "void", [FunctionDeclaration.Param(type)]);
					setter.setProtection(attr.setterProtection);
					resp.addMethod(setter);
				}
				
				objBuilder.addField(field, field.index_);
			}
		}
		
		return null;
	}
}

class HasOneField : IField, IMapping
{
	this(char[] type, char[] name, Field.Attributes attr)
	{
		type_ = type;
		name_ = name;
		attr_ = attr;
	}
	
	private char[] type_;
	private char[] name_;
	private uint index_;
	private Field.Attributes attr_;
	
	uint index() { return index_; }
	
	void writeDecl(IPrint wr)
	{
		if(attr_.getter)
			wr.fln("public {} {}(){{return {}.inst;}",dtype, name, privateName);
		if(attr_.setter) {
			wr.fln("{} void {}({} _val_) {{",
				DeclarationInfo.printProtection(attr_.setterProtection), name, dtype);
			wr.indent;
			wr.fln(`assert(_val_.id != 0, "HasOne of type {} must be saved before being set");`,dtype);
			wr.fln("__touched__[{0}] = true; {1}.inst = _val_; {1}.id = _val_.id;",index,privateName);
			wr.dedent; wr.fln("}");
		}
		wr.fln("private HasOne!({}) {};",dtype,privateName).newline;
	}
	
	char[] isModifiedExpr()
	{
		return "__touched__[" ~ Integer.toString(index)  ~ 
		"] || " ~ privateName ~ ".isModified";
	}
	bool hasGetter() { return attr_.getter; }
	bool hasSetter() { return attr_.setter; }
	bool httpSet() { return false; }
	bool isPrimaryKey() { return false; }
	char[] name() { return name_; }
	char[] fieldAccessor() { return privateName ~ ".id"; }
	char[] privateName() { return name ~ "_"; }
	char[] colname() { return name ~ "_id"; }
	char[] dtype() { return type_; }
	BindType bindType() { return BindType.UInt; }
}