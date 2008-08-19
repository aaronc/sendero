module senderoxc.data.Object;

import senderoxc.data.IDataResponder;

import senderoxc.data.IObjectResponder;
import senderoxc.data.object.Field;
import senderoxc.data.FieldTypes;

import tango.math.Math;

debug import tango.io.Stdout;

class ObjectResponder : IObjectResponder, IObjectBuilder
{
	this(IDataResponder res)
	{
		dataRes_ = res;
	}
	
	IDataResponder dataRes() { return dataRes_; }
	private IDataResponder dataRes_;
	
	void initCtxt(IContextBinder binder)
	{
		debug Stdout.formatln("ObjectResponder.initCtxt");
		foreach(type; FieldTypes)
		{
			debug Stdout.formatln("ObjectResponder.initCtxt type:{}", type.type);
			binder.bindStandaloneDecorator(type.type, new FieldCtxt(this, dataRes, type));
		}
	}
	
	void write(IPrint wr)
	{
		writeIObject(wr); wr.nl;
		writeChangeTracking(wr); wr.nl;
		writeIHttpSet(wr); wr.nl;
		foreach(f; fields) {
			f.writeDecl(wr);
		}	
	}
	
	void writeCheckModifier(char[] delegate(FieldDeclaration))
	{
		
	}
	
	private void writeChangeTracking(IPrint wr)
	{
		wr.fln("private StaticBitArray!({},{}) __touched__;",
			cast(uint)ceil(cast(real)(setterIdx_)/ 32), setterIdx_);
		wr.nl;
	}
	
	private void writeIObject(IPrint wr)
	{		
		wr("Var opIndex(char[] key)\n");
		wr("{\n");
		wr.indent;
		wr("Var res;\n");
		wr("switch(key)\n");
		wr("{\n");
		
		wr.indent;
		foreach(f; fields)
		{
			if(!f.hasGetter) continue;
			wr("case \"" ~ f.name ~ "\": ");
			wr("bind(res, " ~ f.name ~ "()); ");
			wr("break;\n");
		}
		
		wr("default: return Var();\n");
		
		wr.dedent;
		
		wr("}\n");
		wr("return res;\n");
		
		wr.dedent;
		
		wr("}\n");
		
		wr("int opApply (int delegate (inout char[] key, inout Var val) dg) { return 0; }\n");
		
		wr("void opIndexAssign(Var val, char[] key) {}\n");
		
		wr("Var opCall(Var[] params, IExecContext ctxt) { return Var(); }\n");
		
		wr("void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) {}\n");
		
		wr("\n");
	}
	
	private void writeIHttpSet(IPrint wr)
	{
		wr("void httpSet(IObject obj, Request req)\n");
		wr("{\n");
		wr("\tforeach(key, val; obj)\n");
		wr("\t{\n");
		wr("\t\tswitch(key)\n");
		wr("\t\t{\n");
		foreach(f; fields)
		{
			if(!f.hasSetter) continue;
			wr("\t\t\tcase \"" ~ f.name ~ "\": ");
			wr(f.privateName ~ " = convertParam2!(" ~ f.dtype ~ ", Req)(val); ");
			wr("break;\n");
		}
		wr("\t\t\tdefault: break;\n");
		wr("\t\t}\n");
		wr("\t}\n");
		wr("}\n");
	}
	
	void addField(IField field, out uint setterIdx)
	{
		//assert(!(fields.name in fields));
		//fields[field.name] = field;
		fields_ ~= field;
		if(field.hasSetter) setterIdx = setterIdx_;
		++setterIdx_;
	}
	
	//private IField[char[]] fields;
	public IField[] fields() { return fields_; }
	private IField[] fields_;
	private uint setterIdx_;
}