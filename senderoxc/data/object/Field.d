module senderoxc.data.object.Field;

import decorated_d.core.Decoration;

import senderoxc.data.IDataResponder;
import senderoxc.data.IObjectResponder;

import senderoxc.data.Validations;

struct FieldAction
{
	enum {
		None, SerializeColumn, CallInstanceMethod
	}
}

class FieldCtxt : IStandaloneDecoratorContext
{
	this(IObjectBuilder objBuilder, IDataResponder resp, FieldType type)
	{
		this.resp = resp;
		this.type = type;
		this.objBuilder = objBuilder;
	}
	
	IObjectBuilder objBuilder;
	IDataResponder resp;
	FieldType type;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl && decorator.params.length
				&& decorator.params[0].type == VarT.String) {
			auto name = decorator.params[0].string_;
			auto f = Field.createField(type, name, objBuilder, resp, decorator);
			if(f !is null) objBuilder.addField(f, f.index_);
		}
		return null;
	}
}

class Field : IField
{
	static Field createField(FieldType type, char[] name, IObjectBuilder objBuilder, IDataResponder resp, StandaloneDecorator decorator)
	{
		bool getter = true;
		bool setter = true;
		bool map = true;
		
		auto col = Schema.prepColumnInfo(type);
		col.name = name;
		
		if(decorator.params.length > 1 && decorator.params[0].type == VarT.Number)
			col.limit = cast(typeof(col.limit))decorator.params[0].number_;
		
		char[] pname = name ~ "_";
		foreach(dec; decorator.decorators)
		{
			switch(dec.name)
			{
			case "required":
				resp.addValidation(new RequiredRes(type.DType, pname));
				col.notNull = true;
				break;
			case "primaryKey": col.primaryKey = true; break;
			case "autoIncrement": col.autoIncrement = true; setter = false; break;
			case "minLength": resp.addValidation(new InstanceValidationRes("MinLengthValidation", pname, toParamString(dec.params))); break;
			case "maxLength": resp.addValidation(new InstanceValidationRes("MaxLengthValidation", pname, toParamString(dec.params))); break;
			case "regex": resp.addValidation(new InstanceValidationRes("FormatValidation", pname, toParamString(dec.params))); break;// value = a string literal, class = an identifier
			case "minValue": resp.addValidation(new InstanceValidationRes("MinValueValidation", pname, toParamString(dec.params), type.DType)); break;
			case "maxValue": resp.addValidation(new InstanceValidationRes("MaxValueValidation", pname, toParamString(dec.params), type.DType)); break;
			case "no_map": map = false; break;
			default:
				break;
			// validations
			// filters
			// convertors
			}
		}
						
		resp.schema.addColumn(col);
		
		if(map) {
			auto field = new Field(type, name, getter, setter);
			
			resp.addMethod(new FunctionDeclaration(name, type.DType));
			
			if(setter) {
				resp.addMethod(new FunctionDeclaration(name, "void", [FunctionDeclaration.Param(type.DType)]));
			}
			
			return field;
		}
		else return null;
	}
	
	this(FieldType type, char[] name, bool getter, bool setter)
	{
		this.type_ = type;
		this.name_ = name;
		this.setter_ = setter;
		this.getter_ = getter;
	}
	
	char[] privateName()
	{
		return name_ ~ "_";
	}
	
	char[] dtype()
	{
		return type_.DType; 
	}
	
	private FieldType type_;
	
	char[] name() { return name_; }
	char[] colname() { return name_; }
	
	private char[] name_;
	private bool getter_;
	private bool setter_;
	private uint index_;
	
	void writeDecl(IPrint wr)
	{
		//if(map_) {
			if(getter_) {
				wr.fln("public {} {}() {{ return {}_; }", type_.DType, name_, name_);
			}
			
			if(setter_) {
				wr.f("public void {}({} val) {{", name_, type_.DType);
				wr.f("__touched__[{}] = true; {}_ = val;", index_, name_);
				wr.fln("}");
			}
			
			wr.fln("private {} {}_;", type_.DType, name_);

			wr.nl;
		//}
	}
	
	bool hasGetter()
	{
		return getter_;
	}
	
	bool hasSetter()
	{
		return setter_;
	}
	
	char[] isModifiedExpr()
	{
		return "__touched__[" ~ Integer.toString(index_) ~ "]";
	}
}