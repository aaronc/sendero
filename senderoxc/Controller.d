module senderoxc.Controller;

import decorated_d.Decoration;

class ControllerContext : DecoratorContext
{
	DecoratorResponder init(DeclarationInfo decl, ContextBinder binder, Var[] Params = null)
	{
		//binder.bindDecorator(DeclType.Class, "GET");
		//binder.bindDecorator(DeclType.Class, "POST");
		//binder.bindDecorator(DeclType.Class, "PUT");
		//binder.bindDecorator(DeclType.Class, "DELETE");
		
		//binder.bindStandalone("GET");
		//binder.bindStandalone("POST");
		//binder.bindStandalone("PUT");
		//binder.bindStandalone("DELETE");
		//binder.bindStandalone("pass");
		
		return new ControllerResponder(decl);
	}
}

class HTTPMethodContext(Method) : DecoratorContext
{
	this(ControllerResponder resp)
	{
		this.resp = resp;
	}
	
	ControllerResponder resp;
	
	DecoratorResponder init(DeclarationInfo decl, ContextBinder binder, Var[] Params = null)
	{
		return null;
	}
}

class ControllerResponder : DecoratorResponder
{
	this(DeclarationInfo decl)
	{
		this.decl = decl;
	}
	
	DeclarationInfo decl;
	
	void finish(DeclarationWriter writer)
	{
	}
}