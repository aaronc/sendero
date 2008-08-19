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

import dbi.Database;

import senderoxc.data.IDataResponder;

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
			wr.prepend("import sendero_base.Core, sendero.db.Bind, sendero.vm.bind.Bind, sendero.validation.Validations;\n");
			wr.prepend("import sendero.db.DBProvider;\n");
			wr.prepend("import sendero.http.Request, sendero.routing.Convert;\n");
			wr.prepend("import sendero.core.Memory;\n");
			wr.prepend("import sendero.util.collection.StaticBitArray, sendero.util.Singleton;\n");
		}
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		touched = true;
		
		auto res = new DataResponder(decl);
		
		res.objRes.initCtxt(binder);
		
		binder.bindStandaloneDecorator("hasOne", new HasOneCtxt(res));
//		binder.bindStandaloneDecorator("habtm", new HABTMCtxt(res));
		binder.bindStandaloneDecorator("autoPrimaryKey", new AutoPrimaryKeyCtxt(res));
		
		res.init;
		
		return res;
	}
}

class DataResponder : IDecoratorResponder, IDataResponder, IInterfaceWriter
{
	this(DeclarationInfo decl)
	{
		this.decl_ = decl;
		schema_ = Schema.create(decl_.name);
		createFieldInfo;
		hasInterface = findInterface(decl_.name);
		mapper_ = Mapper.create(decl_.name, schema, this);
		objRes_ = new ObjectResponder(this);
	}
	
	IInterface hasInterface;
	char[][] interfaces;
	char[][] imports;
	
	char[] classname() { return decl.name; }
	
	Schema schema() { return schema_; }
	private Schema schema_;
	
	Mapper mapper() { return mapper_; }
	private Mapper mapper_;
	
	ObjectResponder objRes() { return objRes_; }
	private ObjectResponder objRes_;
	
	void init()
	{
		addInterface("IObject");
		addInterface("IHttpSet");
		
		foreach(child;decl.declarations)
		{
			if(child.type == DeclType.Function &&
					!child.isStatic && child.protection == Protection.Public)
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
	
	DeclarationInfo decl() { return decl_; }
	private DeclarationInfo decl_;
	
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
		
		//iobj.finish(wr); wr ~= "\n";
//		schema.write(wr); wr ~= "\n";
		writeIObject(wr.after); wr ~= "\n";
		writeChangeTracking(wr); wr ~= "\n";
		writeIHttpSet(wr); wr ~= "\n";
		writeValidations(wr);  wr ~= "\n";
		writeSessionObject(wr); wr ~= "\n";
		writeErrorSource(wr); wr ~= "\n";
		mapper.write(wr.after);
		objRes.write(wr.after);
		//writeCRUD_(wr); wr ~= "\n";
		/+writeCRUD(wr); wr ~= "\n";+/
		/+wr.addBaseType("IBindable");
		
		wr ~= "static Binder createBinder(char[][] fieldNames = null)\n";
		wr ~= "{\n";
		foreach(cd; decl.declarations)
		{
			
		}
		wr ~= "}\n";+/
	}
	
	void writeIObject(IPrint wr)
	{		
		wr("Var opIndex(char[] key)\n");
		wr("{\n");
		wr.indent;
		wr("Var res;\n");
		wr("switch(key)\n");
		wr("{\n");
		
		wr.indent;
		foreach(getter; getters)
		{
			wr("case \"" ~ getter.name ~ "\": ");
			wr("bind(res, " ~ getter.name ~ "()); ");
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
	
	void writeIHttpSet(IDeclarationWriter wr)
	{
		wr ~= "void httpSet(IObject obj, Request req)\n";
		wr ~= "{\n";
		wr ~= "\tforeach(key, val; obj)\n";
		wr ~= "\t{\n";
		wr ~= "\t\tswitch(key)\n";
		wr ~= "\t\t{\n";
		foreach(setter; setters)
		{
			wr ~= "\t\t\tcase \"" ~ setter.name ~ "\": ";
			wr ~= setter.name ~ " = convertParam2!(" ~ setter.type ~ ", Req)(val); ";
			wr ~= "break;\n";
		}
		wr ~= "\t\t\tdefault: break;\n";
		wr ~= "\t\t}\n";
		wr ~= "\t}\n";
		wr ~= "}\n";
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
	
	void writeErrorSource(IDeclarationWriter wr)
	{
		wr ~= "ErrorMap errors()\n";
		wr ~= "{\n";
		wr ~= "\treturn __errors__;\n";
		wr ~= "}\n";
		
		wr ~= "void clearErrors()\n";
		wr ~= "{\n";
		wr ~= "\t__errors__.reset;\n";
		wr ~= "}\n";
		
		wr ~= "private ErrorMap __errors__;";
	}
	
	void writeChangeTracking(IDeclarationWriter wr)
	{
		wr ~= "private StaticBitArray!(";
		wr ~= Integer.toString(cast(uint)ceil(cast(real)(setters.length)/ 32)) ~ ",";
		wr ~= Integer.toString(setters.length) ~ ") __touched__;\n";
		wr ~= "\n";
	}
	
	void writeCRUD_(IDeclarationWriter wr)
	{
		wr ~= "alias DefaultDatabaseProvider db;\n";
		wr ~= "\n";
		
		wr ~= "private static char[] deleteSql;\n";
		
		wr ~= "public void destroy()\n";
		wr ~= "{\n";
		//wr ~= "\tif(!deleteSql.length) db.sqlGen.makeDeleteSql(\"" ~ decl.name ~ "\", \"id\");\n";
		wr ~= "\tif(!deleteSql.length) deleteSql = db.sqlGen.makeDeleteSql(\"" ~ decl.name ~ "\", [\"id\"]);\n";
		wr ~= "\tscope st = db.prepare(deleteSql);\n";
		wr ~= "\tst.execute(id_);\n";
		wr ~= "}\n";
		wr ~= "\n";
	}
	
	void writeCRUD(IDeclarationWriter wr)
	{
		char[] quoteList(char[][] list, char[] prefix = null)
		{
			char[] res; bool first = true;
			foreach(item; list)
			{
				if(!first) res ~= ", ";
				res ~= `"`;
				if(prefix.length) res ~= prefix ~ "." ~ item;
				else res ~= item;
				res ~= `"`;
				first = false;
			}
			return res;
		}
		
		char[] unquoteList(char[][] list, char[] prefix = null)
		{
			char[] res; bool first = true;
			foreach(item; list)
			{
				if(!first) res ~= ", ";
				if(prefix.length) res ~= prefix ~ "." ~ item;
				else res ~= item;
				first = false;
			}
			return res;
		}
		
		wr ~= "\n";
		
		wr ~= "static this()\n";
		wr ~= "{\n";
		wr ~= "\tauto sqlGen = db.getSqlGenerator;\n";
		
		
		/+char[] insertFields = "[";
 		foreach(cd; decl.declarations)
		{
			if(cd.name == "id")
				continue;
			
			insertFields ~= `"` ~ cd.name ~ `",`;
		}
 		insertFields ~= "\"id\"];";+/
		char[][] insertFields;
		foreach(cd; decl.declarations)
		{
			if(cd.type == DeclType.Field)
				insertFields ~= cd.name;
		}
		
		char[][] fetchFields = insertFields ~ ["id_"];
 		
 		//wr ~= "\tinsertBinder = createBinder(" ~ insertFields ~ ");\n";
		wr ~= "\tauto quote = sqlGen.getIdentifierQuoteCharacter; char[] idQuoted = quote ~ \"id\" ~ quote;\n";
		wr ~= "\tinsertSql = sqlGen.makeInsertSql(\"" ~ decl.name ~ "\",[" ~ quoteList(insertFields) ~ "]);\n";
		wr ~= "\tupdateSql = sqlGen.makeUpdateSql(\"WHERE \" ~ idQuoted ~ \" = ?\", \"" ~ decl.name ~ "\",[" ~ quoteList(insertFields) ~ "]);\n";
		wr ~= "\tselectByIDSq = \"SELECT \" ~ sqlGen.makeFieldList([" ~ quoteList(fetchFields) ~ "]) ~ \" FROM " ~ decl.name ~ " WHERE \" ~ idQuoted ~ \" = ?\");\n";
		wr ~= "\tdeleteSql = \"DELETE FROM " ~ decl.name ~ " WHERE \" ~ idQuoted ~ \" = ?\");\n";
		
		wr ~= "}\n";
		wr ~= "\n";
		
		// Write Save;
		//wr ~= "static Binder insertBinder, updateBinder, fetchBinder;\n";
		wr ~= "const static char[] insertSql, updateSql, selectByIDSql, deleteSql;\n";
		wr ~= "\n";
		
		wr ~= "public bool save()\n";
		wr ~= "{\n";
		wr ~= "\tif(id_) {\n";
		wr ~= "\t\tscope st = db.prepare(updateSql);\n";
		wr ~= "\t\tst.execute(" ~ unquoteList(insertFields) ~ ", id_);\n";
		wr ~= "\t}\n";
		wr ~= "\telse {\n";
		wr ~= "\t\tscope st = db.prepare(insertSql);\n";
		wr ~= "\t\tst.execute(" ~ unquoteList(insertFields) ~ ");\n";
		wr ~= "\t\tid_ = st.getLastInsertID;\n";
		wr ~= "\t}\n";
		wr ~= "\treturn true;";
		wr ~= "}\n";
		wr ~= "\n";
		
		wr ~= "public bool save()\n";
		wr ~= "{\n";
		
		wr ~= "\tif(!__touched__.hasTrue) return true;\n";
		wr ~= "\tif(!this.validate) return false;\n";
		
		// BEGIN Write bindTouched
		
		wr ~= "\tbindTouched(Serializer binder)\n";
		wr ~= "\t{\n";
		
			wr ~= "\t\tforeach(idx, dirty; __touched__)\n";
			wr ~= "\t\t{\n";
				wr ~= "\t\t\tif(dirty) {\n";
					wr ~= "\t\t\t\tswitch(idx)\n";
					wr ~= "\t\t\t\t{\n";
					foreach(idx, setter; setters)
					{
						wr ~= "\t\t\t\tcase " ~ Integer.toString(idx) ~ ":binder.add(\"";
						wr ~= setter.name ~ "\", " ~ setter.colField ~ ");\n";
					}
					wr ~= "\t\t\t\tdefault:debug assert(false);\n";
					wr ~= "\t\t\t\t}\n";
				wr ~= "\t\t\t}\n";
			wr ~= "\t\t}\n";
		
		wr ~= "\t}\n\n";
		
		// END Write bindTouched
		
		wr ~= "\tif(id_) {\n";
		wr ~= "\t\tauto inserter = db.sqlGen.makeInserter;\n";
		wr ~= "\t\tbindTouched(inserter);\n";
		wr ~= "\t\treturn inserter.execute(db);\n";
		wr ~= "\t}\n";
		wr ~= "\telse {\n";
		
		wr ~= "\t\tauto updater = db.sqlGen.makeUpdater;\n";
		wr ~= "\t\tbindTouched(updater);\n";
		wr ~= "\t\treturn updater.execute(db, id_);\n";
		wr ~= "\t}\n";
		wr ~= "\treturn true;\n";
		wr ~= "}\n";	
			
		wr ~= "\n";
		
		wr ~= "public static " ~ decl.name ~ " getByID(uint id)\n";
		wr ~= "{\n";
		wr ~= "\tscope st = db.prepare(selectByIDSql);\n";
		wr ~= "\tst.execute(id_);\n";
		wr ~= "\tauto res = new " ~ decl.name ~ ";\n";
		wr ~= "\tif(st.fetch(";
		wr ~= unquoteList(fetchFields, "res");
		wr ~= ")) return res;\n";
		wr ~= "\telse return null;\n";
		wr ~= "}\n";
		wr ~= "\n";
		
		wr ~= "public bool destroy()\n";
		wr ~= "{\n";
		wr ~= "\tscope st = db.prepare(deleteSql);\n";
		wr ~= "\tst.execute(id_);\n";
		wr ~= "\treturn true;\n";
		wr ~= "}\n";
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


class FieldCtxt : IStandaloneDecoratorContext
{
	this(DataResponder resp, FieldType type)
	{
		this.resp = resp;
		this.type = type;
	}
	DataResponder resp;
	FieldType type;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl) {
			if(decorator.params.length && decorator.params[0].type == VarT.String) {
				auto name = decorator.params[0].string_;
				//resp.schema.columns[name] = resp.schema.newColumn(type, name, decorator);
				
				auto col = Schema.prepColumnInfo(type);
				col.name = name;
				
				if(decorator.params.length > 1 && decorator.params[0].type == VarT.Number)
					col.limit = cast(typeof(col.limit))decorator.params[0].number_;
				
				bool no_map = false;
				bool no_set = false;
				
				char[] pname = name ~ "_";
				foreach(dec; decorator.decorators)
				{
					switch(dec.name)
					{
					case "required":
						resp.addValidation(new RequiredRes(type.DType, pname));
						col.notNull = true;
						break;
					case "primaryKey": col.primaryKey = true; break;
					case "autoIncrement": col.autoIncrement = true; no_set = true; break;
					case "minLength": resp.addValidation(new InstanceValidationRes("MinLengthValidation", pname, toParamString(dec.params))); break;
					case "maxLength": resp.addValidation(new InstanceValidationRes("MaxLengthValidation", pname, toParamString(dec.params))); break;
					case "regex": resp.addValidation(new InstanceValidationRes("FormatValidation", pname, toParamString(dec.params))); break;// value = a string literal, class = an identifier
					case "minValue": resp.addValidation(new InstanceValidationRes("MinValueValidation", pname, toParamString(dec.params), type.DType)); break;
					case "maxValue": resp.addValidation(new InstanceValidationRes("MaxValueValidation", pname, toParamString(dec.params), type.DType)); break;
					case "no_map": no_map = true; break;
					default:
						break;
					// validations
					// filters
					// convertors
					}
				}
								
				resp.schema.addColumn(col);
				
				if(!no_map) {
					resp.addGetter(Getter(type.DType, name));
					
					if(no_set) return new NoSetFieldResponder(type.DType, name);
					else {
						auto idx = resp.addSetter(Setter(type.DType, name, name));
						return new FieldResponder(idx, type.DType, name);
					}
				}
				else return null;
			}
		}
		
		return null;
	}
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

class FieldResponder : AbstractFieldResponder
{
	this(uint index, char[] type, char[] name)
	{
		super(index, type, name);
	}
	
	void finish(IDeclarationWriter wr)
	{
		wr ~= "public " ~ type ~ " " ~  name ~ "() { return " ~  name ~ "_;}\n";
		wr ~= "public void " ~  name ~ "(" ~ type ~ " val) {";
		wr ~= "__touched__[" ~ Integer.toString(index) ~ "] = true; " ~ name ~ "_ = val;";
		wr ~= "}\n";
		wr ~= "private " ~ type ~ " " ~  name ~ "_;\n\n";
	}
}

class NoSetFieldResponder : IDecoratorResponder
{
	this(char[] type, char[] name)
	{
		this.type = type;
		this.name = name;
	}
	char[] type, name;
	
	void finish(IDeclarationWriter wr)
	{
		wr ~= "public " ~ type ~ " " ~  name ~ "() { return " ~  name ~ "_;}\n";
		wr ~= "private " ~ type ~ " " ~  name ~ "_;\n\n";
	}
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
		wr ~= "private HasOne!(" ~ type ~ ") " ~ name ~ "_.get;\n\n";
	}
}

class AutoPrimaryKeyCtxt : IStandaloneDecoratorContext
{
	this(DataResponder resp)
	{
		this.resp = resp;
	}
	DataResponder resp;
	
	IDecoratorResponder init(StandaloneDecorator decorator, DeclarationInfo parentDecl, IContextBinder binder)
	{
		if(resp.decl == parentDecl) {
			char[] name = "id";
			if(decorator.params.length > 0 &&
					decorator.params[0].type == VarT.String) {
				name = decorator.params[0].string_;
			}
			
			resp.getters ~= Getter("uint", name);
			
			auto col = ColumnInfo(name, BindType.UInt);
			col.primaryKey = true;
			col.autoIncrement = true;
			col.notNull = true;
			resp.schema.addColumn(col);
			
			return new AutoPrimaryKeyResponder(name);
		}
		
		return null;
	}
}

class AutoPrimaryKeyResponder : IDecoratorResponder
{
	this(char[] name)
	{
		this.name = name;
	}
	char[] name;
	
	void finish(IDeclarationWriter wr)
	{
		wr ~= "public uint " ~ name ~ "() {return " ~ name ~ "_;}\n";
		wr ~= "private uint " ~ name ~ "_;\n\n";
	}
}
