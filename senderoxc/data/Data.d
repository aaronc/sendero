module senderoxc.data.Data;

import senderoxc.data.IObjectReflector;
import decorated_d.Decoration;

class DataContext : IDecoratorContext
{
	this()
	{
		iobj = new IObjectContext;
	}
	
	IObjectContext iobj;
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		auto res = new DataResponder(decl);
		res.iobj = iobj.init(decl, binder, params);
		//binder.bindDecorator(DeclType.Field, "required");
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

class DataResponder : IDecoratorResponder
{
	this(DeclarationInfo decl)
	{
		this.decl = decl;
	}
	
	DeclarationInfo decl;
	IObjectResponder iobj;
	
	void finish(IDeclarationWriter writer)
	{
		iobj.finish(writer);
		//writer.addBaseType("IBindable");
	}
}