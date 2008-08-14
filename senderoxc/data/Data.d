module senderoxc.data.Data;

import senderoxc.data.IObjectReflector;
import decorated_d.core.Decoration;

import senderoxc.data.Validations;

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
		iobj = new IObjectContext;
	}
	
	IObjectContext iobj;
	
	private bool touched = false;
	
	void writeImports(IDeclarationWriter wr)
	{
		if(touched)
			wr.prepend("import sendero_base.Core, sendero.data.Bind, sendero.vm.bind.Bind, sendero.validation.Validations;\n");
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		touched = true;
		
		auto res = new DataResponder(decl);
		res.iobj = cast(IObjectResponder)iobj.init(decl, binder, params);
		debug assert(res.iobj);
		binder.bindDecorator(DeclType.Field, "required", new TempInstValidCtxt(res, "ExistenceValidation"));
		binder.bindDecorator(DeclType.Field, "minLength", new InstValidCtxt(res, "MinLengthValidation"));
		binder.bindDecorator(DeclType.Field, "maxLength", new InstValidCtxt(res, "MaxLengthValidation"));
		binder.bindDecorator(DeclType.Field, "regex", new InstValidCtxt(res, "FormatValidation")); // value = a string literal, class = an identifier
		binder.bindDecorator(DeclType.Field, "minValue", new TempInstValidCtxt(res, "MinValueValidation"));
		binder.bindDecorator(DeclType.Field, "maxValue", new TempInstValidCtxt(res, "MaxValueValidation"));
		//binder.bindDecorator(DeclType.Field, "xmlEntityFilter");
		//binder.bindDecorator(DeclType.Field, "htmlXSSFilter");
		//binder.bindDecorator(DeclType.Field, "fixedDateTimeParser");
		//binder.bindDecorator(DeclType.Field, "localDateTimeParser");
		//binder.bindDecorator(DeclType.Field, "beforeSave"); // can cancel save
		//binder.bindDecorator(DeclType.Field, "afterSave");
		//binder.bindDecorator(DeclType.Field, "beforeConvertInput"); // can cancel convert
		//binder.bindDecorator(DeclType.Field, "customConvertInput");
		//binder.bindDecorator(DeclType.Field, "afterConvertInput");
		//binder.bindDecorator(DeclType.Field, "customValidate");
		//binder.bindDecorator(DeclType.Field, "beforeRender");
		//binder.bindDecorator(DeclType.Field, "hideRender");
		//binder.bindDecorator(DeclType.Field, "humanize");
		
		return res;
	}
}

class DataResponder : IDecoratorResponder, IDataResponder
{
	this(DeclarationInfo decl)
	{
		this.decl = decl;
	}
	
	DeclarationInfo decl;
	IObjectResponder iobj;
	IValidationResponder[] validations;
	
	void addValidation(IValidationResponder v)
	{
		validations ~= v;
	}
	
	void finish(IDeclarationWriter wr)
	{
		iobj.finish(wr);
		writeIHttpSet(wr);
		writeCRUD(wr);
		/+wr.addBaseType("IBindable");
		
		wr ~= "static Binder createBinder(char[][] fieldNames = null)\n";
		wr ~= "{\n";
		foreach(cd; decl.declarations)
		{
			
		}
		wr ~= "}\n";
		
		wr ~= "static FieldInfo[] reflect()\n";
		wr ~= "{\n";
		
		wr ~= 	"char[] classname = T.stringof;\n"
				"FieldInfo[] info;\n"
		
				"uint n = 0;"
		
				"static if(is(T == class)) {"
					"alias BaseTypeTupleOf!(T) BTT;"
			
					"static if(BTT.length) {"
						"static if(!is(BTT[0] == Object)) {"
							"info ~= ReflectionOf!(BTT[0]).doReflect;"
							"n += info.length;"
						"}"
					"}"
				"}";
				
		
				
		wr ~= "}\n\n";+/
		
		wr ~= "static this()\n";
		wr ~= "{\n";
		foreach(v; validations)
		{
			v.atStaticThis(wr);
		}
		wr ~= "}\n\n";
		
		foreach(v; validations)
		{
			v.atBody(wr);
		}
		wr ~= "\n";
		
		wr ~= "bool validate()\n";
		wr ~= "{\n";
		foreach(v; validations)
		{
			v.atOnValidate(wr);
		}
		wr ~= "\n}\n\n";
		
		//writeIHttpSet(wr);
	}
	
	void writeIHttpSet(IDeclarationWriter wr)
	{
		wr.addBaseType("IHttpSet");
		
		wr ~= "void httpSet(IObject obj, Request req)\n";
		wr ~= "{\n";
		wr ~= "\tforeach(key, val; obj)\n";
		wr ~= "\t{\n";
		wr ~= "\t\tswitch(key)\n";
		wr ~= "\t\t{\n";
		foreach(cd; decl.declarations)
		{
			if(cd.type == DeclType.Field)
			{
				wr ~= "\t\t\tcase \"" ~ cd.name ~ "\": ";
				wr ~= "convertParam2!(typeof(" ~ cd.name ~ "), Req)(" ~ cd.name ~ ", val); ";
				wr ~= "break;\n";
			}
		}
		wr ~= "\t\t\tdefault: break;\n";
		wr ~= "\t\t}\n";
		wr ~= "\t}\n";
		wr ~= "}\n";
	}
	
	void writeSessionObject(IDeclarationWriter wr)
	{
		
	}
	
	void writeCRUD(IDeclarationWriter wr)
	{
		wr ~= "\n";
		
		wr ~= "public uint id() { return id_; }\n";
		wr ~= "private uint id_;\n";
		wr ~= "\n";
		
		wr ~= "static this()\n";
		wr ~= "{\n";
		wr ~= "\tauto sqlGen = db.getSqlGenerator;\n";
		
		
		char[] insertFields = "[";
 		foreach(cd; decl.declarations)
		{
			if(cd.name == "id")
				continue;
			
			insertFields ~= `"` ~ cd.name ~ `",`;
		}
 		insertFields ~= "\"id\"];";
 		
 		wr ~= "\tinsertBinder = createBinder(" ~ insertFields ~ ");\n";		
		wr ~= "\tinsertSql = sqlGen.makeInsertSql(\"" ~ decl.name ~ "\"," ~ insertFields ~ ");\n";
		
		wr ~= "}\n";
		wr ~= "\n";
		
		// Write Save;
		wr ~= "static Binder insertBinder, updateBinder, fetchBinder;\n";
		wr ~= "static char[] insertSql, updateSql, selectByIDSql, deleteSql;\n";
		wr ~= "\n";
		
		wr ~= "public bool save()\n";
		wr ~= "{\n";
		wr ~= "\tif(id_) {\n";
		wr ~= "\t\tscope st = db.prepare(updateSql);\n";
		wr ~= "\t\tst.execute(updateBinder(this));\n";
		wr ~= "\t}\n";
		wr ~= "\telse {\n";
		wr ~= "\t\tscope st = db.prepare(insertSql);\n";
		wr ~= "\t\tst.execute(insertBinder(this));\n";
		wr ~= "\t\tid_ = st.getLastInsertID;\n";
		wr ~= "\t}\n";
		wr ~= "\treturn true;";
		wr ~= "}\n";
		wr ~= "\n";
		
		wr ~= "public static " ~ decl.name ~ " getByID(uint id)\n";
		wr ~= "{\n";
		wr ~= "\tscope st = db.prepare(selectByIDSql);\n";
		wr ~= "\tst.execute(id);\n";
		wr ~= "\tauto res = new " ~ decl.name ~ ";\n";
		wr ~= "\tif(st.fetch(fetchBinder(res))) return res;\n";
		wr ~= "\telse return null;\n";
		wr ~= "}\n";
		wr ~= "\n";
		
		wr ~= "public bool destroy()\n";
		wr ~= "{\n";
		wr ~= "\tscope st = db.prepare(deleteSql);\n";
		wr ~= "\tst.execute(id_);\n";
		wr ~= "\treturn true;\n";
		wr ~= "}\n";
		wr ~= "\n";
	}
}