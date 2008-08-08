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
		binder.bindDecorator(DeclType.Field, "required", new RequiredCtxt(res));
		//binder.bindDecorator(DeclType.Field, "regex"); // value = a string literal, class = an identifier
		//binder.bindDecorator(DeclType.Field, "minLength");
		//binder.bindDecorator(DeclType.Field, "maxLength");
		//binder.bindDecorator(DeclType.Field, "minValue");
		//binder.bindDecorator(DeclType.Field, "maxValue");
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
				
		
				
		wr ~= "}\n\n";
		
		wr ~= "bool validate()\n";
		wr ~= "{\n";
		foreach(v; validations)
		{
			v.atOnValidate(wr);
		}
		wr ~= "\n}\n\n";+/
		
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
				wr ~= "\t\t\tcase \"" ~ cd.name ~ "\":\n";
				
				wr ~= "\t\t\t\tbreak;\n";
			}
		}
		wr ~= "\t\t}\n";
		wr ~= "\t}\n";
		wr ~= "}\n";
	}
	
	void writeSessionObject(IDeclarationWriter wr)
	{
		
	}
	
	void writeCRUD(IDeclarationWriter wr)
	{
		void writeSave()
		{
			
		}
		
		void writeByID()
		{
			
		}
		
		void writeDestroy()
		{
			
		}
	}
}