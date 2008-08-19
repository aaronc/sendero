module senderoxc.data.Object;

import senderoxc.data.IDataResponder;

import senderoxc.data.IObjectResponder;
import senderoxc.data.object.Field;
import senderoxc.data.FieldTypes;

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
		debug Stdout.formatln("ObjectResponder.write");
		foreach(f; fields) {
			debug Stdout.formatln("ObjectResponder.write fields[{}].writeDecl", f.name);
			f.writeDecl(wr);
		}	
	}
	
	void writeCheckModifier(char[] delegate(FieldDeclaration))
	{
		
	}
	
	void addField(IField field)
	{
		fields[field.name] = field; 
	}
	
	private IField[char[]] fields;
}