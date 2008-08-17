module senderoxc.data.Interface;

import decorated_d.core.Decoration;
import senderoxc.data.IInterface;
import sendero.util.Call;

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
			return InterfaceResp.create(name, iname);
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
	private this(char[] name, char[] iname = null)
	{
		this.name = name;
		if(iname.length) this.iname = iname;
		else this.iname = "I" ~ name;
	}
	char[] name, iname;
	
	static InterfaceResp create(char[] name, char[] iname = null)
	{
		auto res = new InterfaceResp(name, iname);
		InterfaceCtxt.interfaces[name] = res;
		InterfaceCtxt.interfaces[iname] = res;
		return res;
	}
	
	void finish(IDeclarationWriter wr)
	{
		
	}
}