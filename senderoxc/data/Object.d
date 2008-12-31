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
		objects[res.classname] = this;
		auto clsDecl = cast(ClassDeclaration)dataRes_.decl;
		assert(clsDecl);
		foreach(base;clsDecl.baseTypes) {
			auto pObj = base in objects;
			if(pObj !is null) {
				parent_ = *pObj;
				parent_.inheritance_ = InheritanceType.SingleTable;
				inheritance_ = InheritanceType.SingleTable;
				pObj.children_[res.classname] = this;
			}
		}
	}
	
	private static ObjectResponder[char[]] objects;
	
	public char[] classname() { return dataRes_.classname; }
	
	public IField[] fields() { return fields_; }
	private IField[] fields_;
	
	public ObjectResponder parent() { return parent_; }
	private ObjectResponder parent_;
	
	public IObjectResponder[char[]] children() { return children_; }
	private IObjectResponder[char[]] children_;
	
	public InheritanceType inheritance()
	{ 
		if(parent !is null) return parent.inheritance;
		return inheritance_;
	}
	private InheritanceType inheritance_ = InheritanceType.None;	
	
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
		writeIBindable(wr); wr.nl;
		foreach(f; fields) {
			f.writeDecl(wr);
		}	
	}
	
	void writeCheckModifier(char[] delegate(FieldDeclaration))
	{
		
	}
	
	private void writeChangeTracking(IPrint wr)
	{
		if(parent !is null) return;
		
		wr.fln("protected StaticBitArray!({},{}) __touched__;",
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
		
		wr("int opApply (int delegate (inout char[] key, inout Var val) dg)\n");
		wr("{\n");
		wr.indent;
			wr("int res; char[] key; Var val;").nl;
			foreach(f; fields)
			{
				if(!f.hasGetter) continue;
				wr.f(`key = "{0}"; bind(val, {0}()); `, f.name);
				wr(`if((res = dg(key, val)) != 0) return res;`).nl;
			}
			wr("return res;").nl;
		wr.dedent;
		wr("}\n");
		
		wr("void opIndexAssign(Var val, char[] key) {}\n");
		
		wr("Var opCall(Var[] params, IExecContext ctxt) { return Var(); }\n");
		
		wr("void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) {}\n");
		
		wr("\n");
	}
	
	private void writeIHttpSet(IPrint wr)
	{
		wr("void httpSet(IObject obj, Request req)\n");
		wr("{\n");
		//wr.fln("static if(is(typeof(this.beforeHttpSet))) if(!this.beforeHttpSet(obj,req)) return false");
		wr("\tforeach(key, val; obj)\n");
		wr("\t{\n");
		wr("\t\tswitch(key)\n");
		wr("\t\t{\n");
		foreach(f; fields)
		{
			if(!f.hasSetter) continue;
			wr("\t\t\tcase \"" ~ f.name ~ "\": ");
			wr(f.privateName ~ " = convertParam!(" ~ f.dtype ~ ", Req)(val, req); ");
			wr("break;\n");
		}
		wr("\t\t\tdefault: break;\n");
		wr("\t\t}\n");
		//wr.fln("static if(is(typeof(this.afterHttpSet))) this.afterHttpSet(obj,req);");
		wr("\t}\n");
		wr("}\n");
	}
	
	size_t bindableFieldCount()
	{
		size_t res = 0;
		foreach(field; fields) ++res;
	
		auto p = this.parent;
		while(p !is null) {
			foreach(field; p.fields)
				++res;
			p = p.parent;
		}
		return res;
	}
	
	private void writeFieldSwitchBody(IPrint wr, void delegate(IPrint wr, IField field) writeField, void delegate(IPrint wr) writeDefault = null)
	{
		wr.fln("switch(name) {{");
		
		foreach(field; fields)
			writeField(wr, field);
		
		auto p = this.parent;
		while(p !is null) {
			foreach(field; p.fields)
				writeField(wr, field);
			p = p.parent;
		}
		
		wr("default:").nl;
		wr.indent;
		if(writeDefault !is null) writeDefault(wr);
		wr.fln(`debug assert(false,"Unknown field name " ~ name ~ " in class {}");`, classname);
		wr("break;").nl;
		wr.dedent;
		wr.fln("}");
	}
	
	private void writeIBindableBody(IPrint wr, void delegate(IPrint wr, IField field) writeField, void delegate(IPrint wr) writeDefault = null)
	{
		wr.fln("{{");
		wr.indent;
			wr.fln(`assert(dst.length >= {0}, "Must provide an array `
				`of at least length {0} to bind items to class {1}");`, bindableFieldCount, classname);
			wr.fln("size_t idx = 0;");
			wr.fln("foreach(name;fieldNames) {{");
			wr.indent;
				writeFieldSwitchBody(wr, writeField, writeDefault);
			wr.dedent;
			wr.fln("}");
			wr.fln("return dst[0..idx];");
		wr.dedent;
		wr.fln("}");
	}
	
	private void field_getBindType(IPrint wr, IField field) {
		wr.fln(`case "{}": dst[idx] = BindType.{}; ++idx; break;`, field.name, field.bindType);
	}
	
	private void field_getBindPtr(IPrint wr, IField field) {
		wr.fln(`case "{}": dst[idx] = &this.{}; ++idx; break;`, field.name, field.privateName);
	}
	
	private void field_getBindPtrOffset(IPrint wr, IField field) {
		wr.fln(`case "{}": dst[idx] = (cast(void*)&this.{} - cast(void*)this); ++idx; break;`, field.name, field.privateName);
	}
	
	private void writeIBindable(IPrint wr)
	{
		wr.fln("BindType[] setBindTypes(char[][] fieldNames, BindType[] dst)");
		writeIBindableBody(wr, &field_getBindType);
		
		wr.fln("void*[] setBindPtrs(char[][] fieldNames, void*[] dst)");
		writeIBindableBody(wr, &field_getBindPtr);
		
		wr.fln("ptrdiff_t[] setBindPtrs(char[][] fieldNames, ptrdiff_t[] dst)");
		writeIBindableBody(wr, &field_getBindPtrOffset);
	}
	
	void addField(IField field, out uint setterIdx)
	{
		//assert(!(fields.name in fields));
		//fields[field.name] = field;
		fields_ ~= field;
		getSetterIdx(field, setterIdx);
	}
	
	private void getSetterIdx(IField field, out uint setterIdx)
	{
		if(parent !is null) return parent.getSetterIdx(field, setterIdx);
		
		if(field.hasSetter) setterIdx = setterIdx_;
		++setterIdx_;
	}
	
	//private IField[char[]] fields;
	private uint setterIdx_;
}