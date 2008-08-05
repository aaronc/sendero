module senderoxc.SenderoExt;

import decorated_d.core.Decoration;

import senderoxc.Controller;
//import senderoxc.data.Data;

import tango.util.log.Log;

import decorated_d.compiler.Process;

Logger log;

static this()
{
	DecoratedDModuleProcessor.autoInitModuleContexts ~= new SenderoExtContext;
	log = Log.lookup("senderoxc.SenderoExt");
}

class SenderoExtContext : IDecoratorContext
{
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		log.info("SenderoExtContext.init");
		binder.bindDecorator(DeclType.Class, "controller", new ControllerContext);
		//binder.bindDecorator(DeclType.Class, "data", new DataContext);
		
		return null;
	}
}