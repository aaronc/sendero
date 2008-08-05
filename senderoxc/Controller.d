module senderoxc.Controller;

import decorated_d.core.Decoration;

import sendero.routing.TypeSafeRouter;

import tango.util.log.Log;

Logger log;

static this()
{
	log = Log.lookup("senderoxc.SenderoExt");
}

class ControllerContext : IDecoratorContext
{
	private bool touched = false;
	
	void writeImports(IDeclarationWriter wr)
	{
		if(touched) {
			wr.prepend("import sendero.routing.TypeSafeRouter, sendero.http.Response, sendero.http.Request, sendero.routing.IRoute;\n");
		}
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		touched = true;
		
		log.info("ControllerContext.init");
		
		auto res = new ControllerResponder(decl);
		
		binder.bindDecorator(DeclType.Function, "GET", new HTTPMethodContext!(GET)(res));
		binder.bindDecorator(DeclType.Function, "POST", new HTTPMethodContext!(POST)(res));
		//binder.bindDecorator(DeclType.Function, "PUT");
		//binder.bindDecorator(DeclType.Function, "DELETE");
		
		//binder.bindStandalone("GET");
		//binder.bindStandalone("POST");
		//binder.bindStandalone("PUT");
		//binder.bindStandalone("DELETE");
		//binder.bindStandalone("pass");
		
		return res;
	}
}

class HTTPMethodContext(ubyte Method) : IDecoratorContext
{
	this(ControllerResponder resp)
	{
		this.resp = resp;
	}
	
	ControllerResponder resp;
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		resp.addAction(Method, decl);
		return null;
	}
}

class ControllerResponder : IDecoratorResponder
{
	this(DeclarationInfo decl)
	{
		this.decl = decl;
	}
	
	DeclarationInfo decl;
	
	void addAction(ubyte method, DeclarationInfo func)
	{
		log.info("ControllerResponder.addAction({},{})", method, func.name);
		actions ~= Action(method, func);
	}
	
	struct Action
	{
		ubyte method;
		DeclarationInfo func;
	}
	
	Action[] actions;
	
	void finish(IDeclarationWriter writer)
	{
		writer ~= "static const TypeSafeRouter!(Res,Req) r, ir;\n";
		writer ~= "static this()\n";
		writer ~= "{\n";
		writer ~= "\tr = TypeSafeRouter!(Response,Request)();\n";
		writer ~= "\tir = TypeSafeRouter!(Response,Request)();\n";
		
		foreach(action; actions)
		{
			char[] method;
			switch(action.method)
			{
			case POST: method = "POST"; break;
			case GET: method = "GET"; break;
			default:
				debug assert(false, "Unknown HTTP Method");
				continue;
			}
			
			char[] i;
			if(!action.func.isStatic) i = "i";
			
			auto fname = decl.name ~ "." ~ action.func.name; 
			writer ~= "\t" ~ i ~ "r.map!(typeof(&" ~ fname ~ `))(` ~ method ~ `,"` ~ action.func.name ~ `", &` ~ fname ~ ", []);\n";
		}
		
		writer ~= "}\n\n";
		
		
		writer ~= "static Res route(Req req)\n";
		writer ~= "{ ";
		writer ~= "return r.route(req);";
		writer ~= " }\n";
		
		writer ~= "Res iroute(Req req)\n";
		writer ~= "{ ";
		writer ~= "return r.route(req);";
		writer ~= " }\n";
	}
}