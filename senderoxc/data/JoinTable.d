module senderoxc.data.JoinTable;

class JoinTableContext : IDecoratorContext
{
	this()
	{
		
	}
	
	IDecoratorResponder init(DeclarationInfo decl, IContextBinder binder, Var[] params = null)
	{
		auto res = new DataResponder(decl);
		assert(res);
		assert(res.obj !is null);
		res.obj.initCtxt(binder);
		
		res.init;
		
		return res;
	}
}