module senderoxc.data.Validations;

import decorated_d.core.Decoration;

interface IDataResponder
{
	void addValidation(IValidationResponder);
}

interface IValidationResponder
{
	void atBody(IDeclarationWriter wr);
	void atOnValidate(IDeclarationWriter wr);
}

class RequiredCtxt : IDecoratorContext
{
	this(IDataResponder resp)
	{ this.resp = resp; }
	IDataResponder resp;
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		if(decl.type != DeclType.Field) return null;
		
		auto fdecl = cast(FieldDeclaration)decl;
		if(fdecl is null) return null;
		
		resp.addValidation(new RequiredRes(fdecl));
		
		return null;
	}
}

class RequiredRes : IValidationResponder
{
	this(FieldDeclaration decl)
	{
		this.decl = decl;
	}
	FieldDeclaration decl;
	
	void atBody(IDeclarationWriter wr)
	{ }
	
	void atOnValidate(IDeclarationWriter wr)
	{
		wr ~= "if(!ExistenceValidation!(" ~ decl.fieldType ~ ").validate("
				~ decl.name ~
				")) ";
		wr ~= "fail(ExistenceValidation!(" ~ decl.fieldType ~ ").error);";
	}
}