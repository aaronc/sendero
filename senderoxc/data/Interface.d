module senderoxc.data.Interface;

import decorated_d.core.Decoration;
import senderoxc.data.IInterface;

class InterfaceCtxt : IStandaloneDecoratorContext
{
	static this()
	{
		Call!("Interface.find", IInterface, char[]).register(&find);
	}
	
	IDecoratorResponder init(StandaloneDecorator dec, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(dec.params.length && dec.params[0].type == VarT.String) {
			char[] name = dec.params[0].string_;
			char[] iname;
			if(dec.params.length > 1 && dec.params[1].type == VarT.String)
				iname = dec.params[1].string_;
			return new InterfaceResp(name, iname);
		}
		
		return null;
	}
	
	static IInterface find(char[] name)
	{
		auto pInterface = name in interfaces;
		if(pInterface !is null) return *pInterface;
		return null;
	}
	
	static InterfaceResp[char[]] interfaces;
}

class InterfaceResp : IInterface, IDecoratorResponder
{
	this(char[] name, char[] iname = null)
	{
		this.name_ = name;
		if(iname.length) this.iname_ = iname;
		else this.iname_ = "I" ~ name;
		
		InterfaceCtxt.interfaces[name_] = this;
		InterfaceCtxt.interfaces[iname_] = this;
	}
	
	char[] iname() { return iname_; }
	char[] name() { return name_; }
	
	private char[] name_, iname_;
	
	void finish(IDeclarationWriter wr)
	{
		wr ~= "interface " ~ iname ~ "{ };";
	}
}