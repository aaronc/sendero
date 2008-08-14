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
		iobj.finish(wr); wr ~= "\n";
		writeIHttpSet(wr); wr ~= "\n";
		writeValidations(wr);  wr ~= "\n";
		writeSessionObject(wr); wr ~= "\n";
		writeErrorSource(wr); wr ~= "\n";
		writeCRUD(wr); wr ~= "\n";
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
	
	void writeValidations(IDeclarationWriter wr)
	{
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
		wr ~= "\tbool succeed = true;\n\n";
		wr ~= "\tvoid fail(char[] field, Error err)";
		wr ~= "\t{\n";
		wr ~= "\t\tsucceed = false;\n";
		wr ~= "\t\terrors_.add(field, err)\n";
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
		wr ~= "\treturn errors_;\n";
		wr ~= "}\n";
		
		wr ~= "void clearErrors()\n";
		wr ~= "{\n";
		wr ~= "\terrors_.reset;\n";
		wr ~= "}\n";
		
		wr ~= "private ErrorMap errors_;";
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
		
		wr ~= "public uint id() { return id_; }\n";
		wr ~= "private uint id_;\n";
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