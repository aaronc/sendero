module senderoxc.Controller;

import decorated_d.core.Decoration;

import sendero.routing.Router;

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
			wr.prepend("import sendero.routing.Router, sendero.http.Request, sendero.routing.IRoute, sendero.view.View;\n");
		}
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		touched = true;
		
		log.info("ControllerContext.init");
		
		auto res = new ControllerResponder(decl);
		
		binder.bindDecorator(DeclType.Function, "GET", new HTTPMethodContext!(GET)(res));
		binder.bindDecorator(DeclType.Function, "POST", new HTTPMethodContext!(POST)(res));
		binder.bindDecorator(DeclType.Function, "PUT", new HTTPMethodContext!(PUT)(res));
		binder.bindDecorator(DeclType.Function, "DELETE", new HTTPMethodContext!(DELETE)(res));
		binder.bindDecorator(DeclType.Function, "ALL", new HTTPMethodContext!(ALL)(res));
		
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
	
	void addAction(ubyte method, DeclarationInfo fDecl)
	{
		auto func = cast(FunctionDeclaration)fDecl;
		if(!func)
			return;
		log.info("ControllerResponder.addAction({},{})", method, func.name);
		actions ~= Action(method, func);
	}
	
	struct Action
	{
		ubyte method;
		FunctionDeclaration func;
	}
	
	Action[] actions;
	
	void finish(IDeclarationWriter writer)
	{
		writer ~= "static const TypeSafeRouter!(Req) r, ir;\n";
		writer ~= "static this()\n";
		writer ~= "{\n";
		writer ~= "\tr = TypeSafeRouter!(Req)();\n";
		writer ~= "\tir = TypeSafeRouter!(Req)();\n";
		
		foreach(action; actions)
		{
			char[] method;
			switch(action.method)
			{
			case POST: method = "POST"; break;
			case GET: method = "GET"; break;
			case PUT: method = "PUT"; break;
			case DELETE: method = "DELETE"; break;
			case ALL: method = "ALL"; break;
			default:
				debug assert(false, "Unknown HTTP Method");
				continue;
			}
			
			char[] i;
			if(!action.func.isStatic) i = "i";
			
			auto sig = action.func.retType ~ " function(";
			bool first = true;
			foreach(p; action.func.params)
			{
				if(!first) sig ~= ",";
				sig ~= p.type;
				first = false;
			}
			sig ~= ")";
			
			auto fname = decl.name ~ "." ~ action.func.name;
			
			auto rname = action.func.name;
			switch(rname)
			{
			case "index":
			case "__default__":
			case "__show__":
			case "__this__":
			case "_":
				rname = "";
				break;
			case "__wildcard__": rname = "*";
			break;
			default: break;
			}
			
			//writer ~= "\t" ~ i ~ "r.map!(typeof(&" ~ fname ~ `))(` ~ method ~ `,"` ~ action.func.name ~ `", &` ~ fname ~ ", [";
			writer ~= "\t" ~ i ~ "r.map!(" ~ sig ~ `)(` ~ method ~ `,"` ~ rname ~ `", &` ~ fname ~ ", [";
			first = true;
			foreach(p; action.func.params)
			{
				if(!first) writer ~= ", ";
				writer ~= '"' ~ p.name ~ '"';
				first = false;
			}
			writer ~= "]);\n";
		}
		
		writer ~= "}\n\n";
		
		
		writer ~= "static void route(Req req)\n";
		writer ~= "{ ";
		writer ~= "return r.route(req);";
		writer ~= " }\n";
		
		writer ~= "void iroute(Req req)\n";
		writer ~= "{ ";
		writer ~= "return r.route(req, cast(void*)this);";
		writer ~= " }\n";
	}
}