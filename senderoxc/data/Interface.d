module senderoxc.data.Interface;

import decorated_d.core.Decoration;
import senderoxc.data.IInterface;
import senderoxc.Reset;

class InterfaceCtxt : IStandaloneDecoratorContext
{
	static this()
	{
		Call!("Interface.find", IInterface, char[]).register(&find);
		SenderoXCReset.onReset.attach(&InterfaceCtxt.reset);
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
	
	private static char[] convertType(char[] type)
	{
		auto iface = find(type);
		if(iface) return iface.iname;
		return type;
	}
	
	static InterfaceResp[char[]] interfaces;
	
	static void reset()
	{
		interfaces = null;
	}
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
	
	char[][] interfaces;
	char[][] imports;
	FunctionDeclaration[] decls;
	
	void addInterface(char[] interfaceName, char[][] imports = null)
	{
		interfaces ~= interfaceName;
	}
	
	void addMethod(FunctionDeclaration decl)
	{
		decls ~= decl;
	}
	
	private char[] name_, iname_;
	
	void finish(IDeclarationWriter wr)
	{
		auto pr = wr.after;
		
		pr.f("interface {}", iname);
		if(interfaces.length) pr(" : ");
		auto len = interfaces.length;
		for(uint i = 0; i < len; ++i) {
			pr(interfaces[i]);
			if(i < len - 1) pr(", ");
		}
		pr.nl;
		pr("{").nl;
		pr.indent;
		
		foreach(decl; decls)
		{
			if(decl.isStatic) continue;
			
			if(decl.protection == Protection.Private || decl.protection == Protection.Protected)
				continue;
			
			char[] params;
			len = decl.params.length;
			for(uint i = 0; i < len; ++i) {
				params ~= InterfaceCtxt.convertType(decl.params[i].type);
				if(decl.params[i].name.length)
					params ~= " " ~ decl.params[i].name;
				if(i < len - 1) params ~= ", ";
			}
			
			//if(decl.isStatic) pr("static ");
			pr.fln("{} {}({});", InterfaceCtxt.convertType(decl.retType), decl.name, params);
		}
		
		pr.dedent;
		pr("}").nl;
		pr.fln("alias Construct!({}).create construct{};", iname, name);
		
	}
	
	void writeCallRegisters(IDeclarationWriter wr)
	{
		auto pr = wr.after;
		
		wr ~= "static this()\n";
		wr ~= "{\n";
		wr ~= "\tConstruct!(";
		wr ~= iname;
		wr ~= ").register(&create);\n";
		pr.indent;
		/+foreach(child; decls)
		{
			if(!child.isStatic) continue;
			
			pr.f(`Call!("{}", {}`, child.name, InterfaceCtxt.convertType(child.retType));
			auto nParams = child.params.length;
			foreach(p; child.params)
			{
				pr(", ");
				pr(InterfaceCtxt.convertType(p.type));
			}
			pr.fln(").register(&{});", child.name);
			
		}+/
		pr.dedent;
		wr ~= "}\n";
		
		wr ~= "static ";
		wr ~= iname;
		wr ~= " create()\n";
		wr ~= "{\n";
		wr ~= "\treturn new ";
		wr ~= name;
		wr ~= ";\n}\n";
		
	}
}