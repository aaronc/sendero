module senderoxc.Cyclic;

import decorated_d.core.Decoration;
import senderoxc.Compiler;

class CyclicContext : IStandaloneDecoratorContext
{
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(decorator.params.length && decorator.params[0].type == VarT.String)
			return new CyclicResponder(decorator.params[0].string_);
		else return null;
	}
}

class CyclicResponder : IDecoratorResponder
{	
	this(char[] modname)
	{
		this.modname = modname;
	}
	char[] modname;
	
	void finish(IDeclarationWriter writer)
	{
		auto compiler = new SenderoXCCompiler();
		writer ~= compiler.justCompile(modname);
	}
}