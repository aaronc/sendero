module senderoxc.data.Validations;

import decorated_d.core.Decoration;

import Float = tango.text.convert.Float;

interface IDataResponder
{
	void addValidation(IValidationResponder);
}

interface IValidationResponder
{
	void atStaticThis(IDeclarationWriter wr);
	void atBody(IDeclarationWriter wr);
	void atOnValidate(IDeclarationWriter wr);
}

abstract class DataResponderCtxt : IDecoratorContext
{
	this(IDataResponder resp)
	{ this.resp = resp; }
	IDataResponder resp;
	
	abstract IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null);

}

class RequiredCtxt : DataResponderCtxt
{
	this(IDataResponder resp) { super(resp); }
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		if(decl.type != DeclType.Field) return null;
		auto fdecl = cast(FieldDeclaration)decl; if(fdecl is null) return null;
		resp.addValidation(new RequiredRes(fdecl));
		return null;
	}
}

char[] toParamString(Var[] params)
{
	char[] res; bool first = true;
	foreach(var; params)
	{
		switch(var.type)
		{
		case VarT.String:
			res ~= `"` ~ var.string_ ~ `"`;
			break;
		case VarT.Number:
			res ~= Float.toString(var.number_, 0);
			break;
		default:
			throw new Exception("Unhandled param type in toParamString");
		}
		
		if(!first) {
			res ~= ",";
		}
		first = false;
	}
	return res;
}

class InstValidCtxt : DataResponderCtxt
{
	this(IDataResponder resp, char[] type)
	{
		super(resp);
		this.type = type;
	}
	char[] type;
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		if(decl.type != DeclType.Field) return null;
		auto fdecl = cast(FieldDeclaration)decl; if(fdecl is null) return null;
		resp.addValidation( new InstanceValidationRes(fdecl, type, toParamString(params)) );
		return null;
	}
}

class TempInstValidCtxt : DataResponderCtxt
{
	this(IDataResponder resp, char[] type)
	{
		super(resp);
		this.type = type;
	}
	char[] type;
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		if(decl.type != DeclType.Field) return null;
		auto fdecl = cast(FieldDeclaration)decl; if(fdecl is null) return null;
		resp.addValidation( new InstanceValidationRes(fdecl, type, toParamString(params), fdecl.fieldType));
		return null;
	}
}


class MinLengthCtxt : DataResponderCtxt
{
	this(IDataResponder resp) { super(resp); }
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		if(decl.type != DeclType.Field) return null;
		auto fdecl = cast(FieldDeclaration)decl; if(fdecl is null) return null;
		resp.addValidation(new InstanceValidationRes(fdecl, "MinLengthValidation", toParamString(params)));
		return null;
	}
}


abstract class ValidationResponder : IValidationResponder
{
	this(FieldDeclaration decl)
	{
		this.decl = decl;
	}
	FieldDeclaration decl;
	
	void atStaticThis(IDeclarationWriter wr)
	{ }
	
	void atBody(IDeclarationWriter wr)
	{ }
	
	void atOnValidate(IDeclarationWriter wr)
	{	}
}

class RequiredRes : ValidationResponder
{
	this(FieldDeclaration decl) { super(decl); }
	
	void atOnValidate(IDeclarationWriter wr)
	{
		wr ~= "\tif(!ExistenceValidation!(" ~ decl.fieldType ~ ").validate("
				~ decl.name ~
				")) ";
		wr ~= "fail(\"" ~ decl.name ~ "\", ExistenceValidation!(" ~ decl.fieldType ~ ").error);\n";
	}
}

class InstanceValidationRes : ValidationResponder
{
	this(FieldDeclaration decl, char[] type, char[] constructParams = null, char[] templateParams = null)
	{
		super(decl);
		this.type = type;
		this.constructParams = constructParams;
		this.templateParams = templateParams;
		
	}
	char[] type, constructParams, templateParams;
	
	void atStaticThis(IDeclarationWriter wr)
	{
		wr ~= "\t" ~  decl.name ~ type ~ " = new " ~ type;
		if(templateParams.length) wr ~= "!(" ~ templateParams ~ ")";
		wr ~= "(" ~ constructParams ~ ")";
		wr ~= ";\n";
	}
	
	void atBody(IDeclarationWriter wr)
	{
		wr ~= "static " ~ type;
		if(templateParams.length) wr ~= "!(" ~ templateParams ~ ")";
		wr ~= " " ~ decl.name ~ type ~ ";\n";
	}
	
	void atOnValidate(IDeclarationWriter wr)
	{
		wr ~= "\tif(!" ~ decl.name ~ type ~ ".validate("
				~ decl.name ~
				")) ";
		wr ~= "fail(\"" ~ decl.name ~ "\", " ~ decl.name ~ type ~ ".error);\n";
	}
}