module senderoxc.SenderoExt;

import decorated_d.Decoration;

import senderoxc.Controller;
import senderoxc.Data;

class SenderoExtContext : DecoratorContext
{
	DecoratorResponder init(DeclarationInfo decl, ContextBinder binder, Var[] Params = null)
	{
		binder.bindDecorator(DeclType.Class, "controller", new ControllerContext);
		binder.bindDecorator(DeclType.Class, "data", new DataContext);
	}
}