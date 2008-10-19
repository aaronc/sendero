module sendero.view.View;

//public import sendero.http.Request;
public import sendero.http.Response;
import sendero.http.IRenderable;

import sendero.view.SenderoTemplate;
import sendero.view.ExecContext;
import sendero.vm.Bind;

import sendero_base.util.ArrayWriter;
import sendero_base.json.Printer;

debug(SenderoRuntime) {
	import sendero.Debug;
	static this() { log = Log.lookup("debug.SenderoRuntime"); }
	Logger log;
}

class View : IRenderable
{
	static this()
	{
		SenderoTemplate.setSearchPath("view/");
	}
	
	this(SenderoTemplateContext t, char[] contentType)
	{
		this.contentType_ = contentType;
		ctxt = t;
	}

	protected SenderoTemplateContext ctxt;
	
	public char[] contentType() { return contentType_; }
	protected char[] contentType_;
	
	/+Response render()
	{
		Response res;
		res.contentType = contentType;
		res.contentDelegate = &ctxt.render;
		return res;
	}+/
	
	void render(void delegate(void[]) consumer)
	{
		ctxt.render(consumer);
	}

	static View get(char[] name, char[] type = Mime.TextHtml)
	{
		debug(SenderoRuntime) mixin(FailTrace!("View.get"));
		debug(SenderoRuntime) log.trace(MName ~ "({}, {})", name, type);
		
		auto ctxt = SenderoTemplate.get(name, "en-US");
		return new View(ctxt, type);
	}
	
	void opIndexAssign(T)(T t, char[] name)
	{
		ctxt[name] = t;
	}
	
	void use(T)(T t)
	{
		ctxt.use(t);
	}
	
	/+Res renderJson()
	{
		Response res;
		res.contentType = Res.TextJSON;
		res.contentDelegate = delegate void(void delegate(void[]) write) {
			printObj(ctxt.execCtxt, cast(void delegate(char[]))write);
		};
		return res;
	}+/
}

class JsonView : IRenderable
{
	this()
	{
		ctxt = new ExecContext;
	}
	
	ExecContext ctxt;
	
	void opIndexAssign(T)(T t, char[] name)
	{
		Var v;	bind(v, t);
		ctxt[name] = v;
	}
	
	void use(T)(T t)
	{
		//TODO
		ctxt.addVarAsRoot(t);
	}
	
	/+Res renderJson()
	{
		Response res;
		res.contentType = Res.TextJSON;
		res.contentDelegate = delegate void(void delegate(void[]) write) {
			printObj(ctxt, cast(void delegate(char[]))write);
		};
		return res;
	}
	
	alias renderJson render;+/
	
	public char[] contentType() { return Mime.TextJson; }
	
	void render(void delegate(void[]) consumer)
	{
		printObj(ctxt, cast(void delegate(char[]))consumer);
	}
	
}
/+
Res renderJson(IObject obj)
{
	Response res;
	res.contentType = Res.TextJSON;
	res.contentDelegate = delegate void(void delegate(void[]) write) {
		printObj(obj, cast(void delegate(char[]))write);
	};
	return res;
}+/