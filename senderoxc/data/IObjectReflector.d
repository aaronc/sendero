module senderoxc.data.IObjectReflector;

import decorated_d.core.Decoration;

class IObjectContext : IDecoratorContext
{
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] Params = null)
	{
		//binder.bindDecorator(DeclType.Field, "xmlEntityFilter");
		//binder.bindDecorator(DeclType.Field, "htmlXSSFilter");
		//binder.bindDecorator(DeclType.Field, "beforeRender");
		//binder.bindDecorator(DeclType.Field, "hideRender");
		//binder.bindDecorator(DeclType.Field, "humanize");
		
		return new IObjectResponder(decl);
	}
}

class IObjectResponder : IDecoratorResponder
{
	this(DeclarationInfo decl)
	{
		this.decl = decl;
	}
	
	DeclarationInfo decl;
	
	void finish(IDeclarationWriter wr)
	{
		wr.addBaseType("IObject");
		
		wr ~= "Var opIndex(char[] key)\n";
		wr ~= "{\n";
		wr ~= "\tVar res;\n";
		wr ~= "\tswitch(key)\n";
		wr ~= "\t{\n";
		
		foreach(cd; decl.declarations)
		{
			if(cd.type == DeclType.Field && cd.protection == Protection.Public) {
				wr ~= "\t\tcase \"" ~ cd.name ~ "\": ";
				wr ~= "bind(var, " ~ cd.name ~ "); ";
				wr ~= "break;\n";
			}
		}
		
		wr ~= "\t\tdefault: return Var();\n";
		wr ~= "\t}\n";
		wr ~= "\treturn res;\n";
		
		wr ~= "}\n";
		
		wr ~= "int opApply (int delegate (inout char[] key, inout Var val) dg) {}\n";
		
		wr ~= "void opIndexAssign(Var val, char[] key) {}\n";
		
		wr ~= "Var opCall(Var[] params, IExecContext ctxt) {}\n";
		
		wr ~= "void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) {}\n";
		
		wr ~= "\n";
	}
}
