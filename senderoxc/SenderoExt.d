module senderoxc.SenderoExt;

import decorated_d.core.Decoration;

import senderoxc.Controller;
import senderoxc.data.Data;
import senderoxc.data.Interface;

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
		auto cCtxt = new ControllerContext;
		binder.bindDecorator(DeclType.Class, "controller", cCtxt);
		auto dCtxt = new DataContext;
		binder.bindDecorator(DeclType.Class, "data", dCtxt);
		binder.bindStandaloneDecorator("dataInterface", new InterfaceCtxt);
		binder.bindStandaloneDecorator("initDatabase", new InitDatabaseContext);
		
		return new SenderoExtResponder(cCtxt, dCtxt);
	}
}

class SenderoExtResponder : IDecoratorResponder
{
	this(ControllerContext cCtxt, DataContext dCtxt)
	{
		this.cCtxt = cCtxt;
		this.dCtxt = dCtxt;
	}
	ControllerContext cCtxt; DataContext dCtxt;
	
	void finish(IDeclarationWriter wr)
	{
		wr.prepend("\n\n");
		cCtxt.writeImports(wr);
		dCtxt.writeImports(wr);
	}
}