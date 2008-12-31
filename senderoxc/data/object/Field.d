module senderoxc.data.object.Field;

import decorated_d.core.Decoration;

import senderoxc.data.IDataResponder;
import senderoxc.data.IObjectResponder;

import senderoxc.data.Validations;

import Integer = tango.text.convert.Integer;

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
			if(f !is null) {
				objBuilder.addField(f, f.index_);
				if(f.hasSetter) resp.mapper.addMapping(f);
			}
		}
		return null;
	}
}

class AutoPrimaryKeyCtxt : IStandaloneDecoratorContext
{
	this(IObjectBuilder objBuilder, IDataResponder resp)
	{
		this.resp = resp;
		this.objBuilder = objBuilder;
		this.type = FieldType("UInt","uint", BindType.UInt);
	}
	
	IObjectBuilder objBuilder;
	IDataResponder resp;
	FieldType type;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl && decorator.params.length
				&& decorator.params[0].type == VarT.String) {
			auto name = decorator.params[0].string_;
			Field.Attributes attr;
			auto col = Schema.prepColumnInfo(type);
			col.name = name;
			
			char[] pname = name ~ "_";
			attr.primaryKey = true;
			attr.setter = false;
			attr.getter = true;
			col.primaryKey = true;
			col.autoIncrement = true;
							
			resp.schema.addColumn(col);
			
			auto field = new Field(type, name, attr);
			
			resp.addMethod(new FunctionDeclaration(name, type.DType));
			
			objBuilder.addField(field, field.index_);
		}
		return null;
	}
}

class Field : IField, IMapping
{
	static Field createField(FieldType type, char[] name, IObjectBuilder objBuilder, IDataResponder resp, StandaloneDecorator decorator)
	{
		Attributes attr;
		
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
			case "primaryKey": col.primaryKey = true; attr.primaryKey = true; break;
			case "autoIncrement": col.autoIncrement = true; attr.setter = false; break;
			case "minLength": resp.addValidation(new InstanceValidationRes("MinLengthValidation", pname, toParamString(dec.params))); break;
			case "maxLength": resp.addValidation(new InstanceValidationRes("MaxLengthValidation", pname, toParamString(dec.params))); break;
			case "regex": resp.addValidation(new InstanceValidationRes("FormatValidation", pname, toParamString(dec.params))); break;// value = a string literal, class = an identifier
			case "minValue": resp.addValidation(new InstanceValidationRes("MinValueValidation", pname, toParamString(dec.params), type.DType)); break;
			case "maxValue": resp.addValidation(new InstanceValidationRes("MaxValueValidation", pname, toParamString(dec.params), type.DType)); break;
			case "no_map": map = false; break;
			case "no_setter": attr.setter = false; break;
			case "privateSetter": attr.setterProtection = Protection.Private; break;
			case "protectedSetter": attr.setterProtection = Protection.Protected; break;
			case "packageSetter": attr.setterProtection = Protection.Package; break;
			default:
				break;
			// validations
			// filters
			// convertors
			}
		}
						
		resp.schema.addColumn(col);
		
		if(map) {
			auto field = new Field(type, name, attr);
			
			resp.addMethod(new FunctionDeclaration(name, type.DType));
			
			if(attr.setter) {
				auto setter = new FunctionDeclaration(name, "void", [FunctionDeclaration.Param(type.DType)]);
				setter.setProtection(attr.setterProtection);
				resp.addMethod(setter);
			}
			
			return field;
		}
		else return null;
	}
	
	this(FieldType type, char[] name, Attributes attr)
	{
		this.type_ = type;
		this.name_ = name;
		this.attr_ = attr;
	}
	
	char[] privateName()
	{
		return name_ ~ "_";
	}
	
	char[] dtype()
	{
		return type_.DType; 
	}
	
	BindType bindType()
	{
		return type_.bindType;
	}
	
	char[] fieldAccessor()
	{
		return privateName;
	}
	
	private FieldType type_;
	
	char[] name() { return name_; }
	char[] colname() { return name_; }
	
	struct Attributes
	{
		bool getter = true;
		bool setter = true;
		bool primaryKey = false;
		Protection setterProtection = Protection.Public;
	}
	
	private char[] name_;
	private uint index_;
	private Attributes attr_;
	
	void writeDecl(IPrint wr)
	{
		if(attr_.getter) {
			wr.fln("public {} {}() {{ return {}_; }", type_.DType, name_, name_);
		}
		
		if(attr_.setter) {
			wr.f("{} void {}({} _val_) {{",
				DeclarationInfo.printProtection(attr_.setterProtection), name_, type_.DType);
			wr.f("__touched__[{}] = true; {}_ = _val_;", index_, name_);
			wr.fln("}");
		}
		
		wr.fln("protected {} {};", type_.DType, privateName);

		wr.nl;
	}
	
	bool hasGetter()
	{
		return attr_.getter;
	}
	
	bool hasSetter()
	{
		return attr_.setter;
	}
	
	bool isPrimaryKey()
	{
		return attr_.primaryKey;
	}
	
	bool httpSet()
	{
		return hasSetter;
	}
	
	char[] isModifiedExpr()
	{
		return "__touched__[" ~ Integer.toString(index_) ~ "]";
	}
}