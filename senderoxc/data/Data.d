module senderoxc.data.Data;

import decorated_d.core.Decoration;

import senderoxc.data.Object;
import senderoxc.data.Schema;
import senderoxc.data.Validations;
import senderoxc.data.Mapper;
import senderoxc.data.IInterface;

public import senderoxc.util.CodeGen;
import Integer = tango.text.convert.Integer;
import tango.math.Math;

import tango.core.Signal;
import sendero.util.Call;

import dbi.DBI;

import senderoxc.data.IDataResponder;

import tango.util.log.Log;
Logger log;
static this()
{
	log = Log.lookup("senderoxc.data.Data");
}

/*
 * TODO:
 * 
 * IObject
 * IHttpSet, (IHttpGet)
 * IBindable
 * validate(), (reflection)
 * errors(), (other error message handling, reflection...)
 * save (update & create), destroy, static byId (read) (if has id & type == integral)
 * SessionObject
 */

class DataContext : IDecoratorContext
{
	this()
	{
		
	}
	
	private bool touched = false;
	
	void writeImports(IDeclarationWriter wr)
	{
		if(touched) {
			wr.prepend("import sendero_base.Core, sendero.db.Bind, sendero.vm.Bind, sendero.msg.Msg;\n");
			wr.prepend("import sendero.db.DBProvider;\n");
			wr.prepend("import sendero.http.Request, sendero.routing.Convert;\n");
			wr.prepend("import sendero.core.Memory;\n");
			wr.prepend("import sendero.util.collection.StaticBitArray, sendero.util.Singleton;\n");
			wr.prepend("import sendero.util.Call;\n");
			wr.prepend("import sendero.db.Relations;\n");
		}
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		touched = true;
		
		auto res = new DataResponder(decl);
		assert(res);
		assert(res.obj !is null);
		res.obj.initCtxt(binder);
		
		//binder.bindStandaloneDecorator("hasOne", new HasOneCtxt(res));
		//binder.bindStandaloneDecorator("habtm", new HABTMCtxt(res));
		//binder.bindStandaloneDecorator("autoPrimaryKey", new AutoPrimaryKeyCtxt(res));
		
		res.init;
		
		return res;
	}
}

class InitDatabaseContext : IStandaloneDecoratorContext
{	
	IDecoratorResponder init(StandaloneDecorator dec, DeclarationInfo parentDecl, IContextBinder binder)
	{
		return new InitDatabaseResponder;
	}
}

class InitDatabaseResponder : IDecoratorResponder
{
	void finish(IDeclarationWriter writer)
	{
		auto wr = writer.after;
		
		wr.fln("import sendero.db.DBProvider;");
		/+wr.fln("static DBProvider!() mainDBProvider;");
		wr.fln("static this() {{"); wr.indent;
		wr.fln("auto dbPool = new DefaultDatabasePool;");
		wr.fln("mainDBProvider = new DBProvider!()(dbPool);");
		wr.dedent; wr.fln("}");+/
		wr.fln("alias DBProvider!(DefaultDatabasePool) mainDBProvider;");
	}
}

class DataResponder : IDecoratorResponder, IDataResponder, IInterfaceWriter
{
	this(DeclarationInfo declaration)
	{
		this.decl_ = declaration;
		this.obj_ = new ObjectResponder(this);
		if(this.obj_.parent !is null) this.schema_ = this.obj_.parent.dataRes.schema;
		else this.schema_ = Schema.create(decl_.name);
		
		createFieldInfo;
		this.hasInterface = findInterface(decl_.name);
		this.mapper_ = Mapper.create(decl_.name, this);
		
		debug log.trace("Done constructing DataResponder for {}", classname);
		
		assert(decl_ !is null);
		assert(schema_ !is null);
		assert(mapper_ !is null);
		assert(obj_ !is null);
	}
	
	IInterface hasInterface;
	char[][] interfaces;
	char[][] imports;
	
	char[] classname() { return decl.name; }
	
	DeclarationInfo decl() { return decl_; }
	private DeclarationInfo decl_;
	
	Schema schema() { return schema_; }
	private Schema schema_;
	
	ObjectResponder obj() { assert(this.obj_ !is null, classname); return this.obj_; }
	private ObjectResponder obj_;
	
	Mapper mapper() { return mapper_; }
	private Mapper mapper_;
	
	void init()
	{
		obj.initInterface;
		
		foreach(child;decl.declarations)
		{
			if(child.type == DeclType.Function && child.protection == Protection.Public)
			{
				auto fdecl = cast(FunctionDeclaration)child;
				assert(fdecl);
				addMethod(fdecl);
			}
		}
		
		mapper.init;
	}
	
	void addInterface(char[] interfaceName, char[][] imports = null)
	{
		if(hasInterface) {
			hasInterface.addInterface(interfaceName, imports);
		}
		else {
			interfaces ~= interfaceName;
			imports ~= imports;
		}
	}
	
	void addMethod(FunctionDeclaration decl)
	{
		if(hasInterface) {
			hasInterface.addMethod(decl);
		}
	}
	
	void createFieldInfo()
	{
		foreach(cd; decl.declarations)
		{
			if(cd.type == DeclType.Field)
			{
				auto fdecl = cast(FieldDeclaration)cd;
				if(fdecl) fieldInfo[fdecl.name] = new FieldInfo(fdecl);
			}
		}
	}
	
	class FieldInfo
	{
		this(FieldDeclaration fdecl)
		{ this.fdecl = fdecl; }
		FieldDeclaration fdecl;
	}
	
	FieldInfo[char[]] fieldInfo;
	
	IValidationResponder[] validations;
	
	void addValidation(IValidationResponder v)
	{
		validations ~= v;
	}
	
	void addGetter(Getter getter)
	{
		getters ~= getter;
		addMethod(new FunctionDeclaration(getter.name, getter.type));
	}
	
	uint addSetter(Setter setter)
	{
		setters ~= setter;
		addMethod(new FunctionDeclaration(setter.name, "void", [FunctionDeclaration.Param(setter.type)]));
		return setters.length - 1;
	}
	
	private Getter[] getters;
	
	private Setter[] setters;
	
	void finish(IDeclarationWriter wr)
	{
		if(hasInterface) wr.addBaseType(hasInterface.iname);
		
		foreach(iface; interfaces)
			wr.addBaseType(iface);
		
		if(hasInterface) {
			hasInterface.writeCallRegisters(wr);
		}
		
		//writeValidations(wr);  wr ~= "\n";
		writeSessionObject(wr); wr ~= "\n";
		mapper.write(wr.after);
		obj.write(wr.after);
	}

	void writeValidations(IDeclarationWriter wr)
	{
		/+wr ~= "static this()\n";
		wr ~= "{\n";
		foreach(v; validations)
		{
			v.atStaticThis(wr);
		}
		wr ~= "}\n\n";+/
		
		foreach(v; validations)
		{
			v.atBody(wr);
		}
		wr ~= "\n";
		
		wr ~= "bool validate()\n";
		wr ~= "{\n";
		wr ~= "\tbool succeed = true;\n\n";
		wr ~= "\tvoid fail(char[] field, Error err)";
		wr ~= "\t{\n";
		wr ~= "\t\tsucceed = false;\n";
		wr ~= "\t\t__errors__.add(field, err);\n";
		wr ~= "\t}\n\n";
		
		foreach(v; validations)
		{
			v.atOnValidate(wr);
		}
		
		wr ~= "\n\treturn succeed;";
		
		wr ~= "\n}\n\n";
	}
	
	void writeSessionObject(IDeclarationWriter wr)
	{
		wr ~= "mixin SessionAllocate!();\n";
	}
}

struct Getter
{
	char[] type;
	char[] name;
}

struct Setter
{
	char[] type;
	char[] name;
	char[] colField;
}

class AbstractFieldResponder : IDecoratorResponder
{
	this(uint index, char[] type, char[] name)
	{
		this.index = index;
		this.type = type;
		this.name = name;
	}
	uint index;
	char[] type, name;
	
	abstract void finish(IDeclarationWriter wr);
}

class ClassTableInheritanceCtxt : IStandaloneDecoratorContext
{
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		return null;
	}
}


class HasOneCtxt : IStandaloneDecoratorContext
{	
	this(DataResponder resp)
	{
		this.resp = resp;
	}
	DataResponder resp;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl) {
			if(decorator.params.length > 1 &&
					decorator.params[0].type == VarT.String &&
					decorator.params[1].type == VarT.String) {
				auto type = decorator.params[0].string_;
				auto name = decorator.params[1].string_;
				resp.addGetter(Getter(type, name));
				
				auto col = ColumnInfo(name ~ "_id", BindType.UInt);
				resp.schema.addColumn(col);
				
				auto idx = resp.addSetter(Setter(type, name, name ~ ".id_"));
				return new HasOneResponder(idx, type, name);
			}
		}
		
		return null;
	}
}

class HasOneResponder : AbstractFieldResponder
{
	this(uint index, char[] type, char[] name)
	{
		super(index, type, name);
	}
	
	void finish(IDeclarationWriter wr)
	{
		wr ~= "public " ~ type ~ " " ~ name ~ "() {return " ~ name ~ "_;}\n";
		wr ~= "public void " ~  name ~ "(" ~ type ~ " val) {";
		wr ~= "__touched__[" ~ Integer.toString(index) ~ "] = true; " ~ name ~ "_ = val;";
		wr ~= "}\n";
		wr ~= "private HasOne!(" ~ type ~ ") " ~ name ~ "_;\n\n";
	}
}