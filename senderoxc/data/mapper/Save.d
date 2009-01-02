module senderoxc.data.mapper.Save;

import senderoxc.data.mapper.IMapper;

class SaveResponder(MapperT = IMapper) : IMapperResponder
{
	this(MapperT m)
	{
		this.mapper = m;
		
		if(mapper.schema.getPrimaryKeyCols.length  == 1) {
			mapper.addMethod(new FunctionDeclaration("save", "bool"));
		}
	}
	protected MapperT mapper;
	
	void write(IPrint wr)
	in
	{
		assert(mapper);
		assert(mapper.schema);
		assert(mapper.obj);
		assert(wr);
	}
	body
	{
		if(mapper.schema.getPrimaryKeyCols.length != 1)
			return;
		
		wr.fln("bool save()");
		wr("{").nl;
		wr.indent;
		
		wr.fln("static if(is(typeof(this.beforeValidation))) if(!this.beforeValidation) return false;");
		wr.fln("static if(is(typeof(this.beforeValidationOnCreate))) if(!id_ && !this.beforeValidationOnCreate) return false;");
		wr.fln("static if(is(typeof(this.beforeValidationOnUpdate))) if(id_ && !this.beforeValidationOnUpdate) return false;");
		
		
		wr.fln("if(!validate) return false;");
		wr.fln("static if(is(typeof(this.validateOnCreate))) if(!id_ && !this.validateOnCreate) return false;");
		wr.fln("static if(is(typeof(this.validateOnUpdate))) if(id_ && !this.validateOnUpdate) return false;");
		
		wr.fln("static if(is(typeof(this.afterValidation))) if(!this.afterValidation) return false;");
		wr.fln("static if(is(typeof(this.afterValidationOnCreate))) if(!id_ && !this.afterValidationOnCreate) return false;");
		wr.fln("static if(is(typeof(this.afterValidationOnUpdate))) if(id_ && !this.afterValidationOnUpdate) return false;");
		
		wr.fln("static if(is(typeof(this.beforeSave))) if(!this.beforeSave) return false;");
		
		wr.fln("auto db = getDb();");
		wr.fln("char[][{}] fields;",mapper.obj.bindableFieldCount);
		wr.fln("BindType[{}] bindTypes;",mapper.obj.bindableFieldCount);
		wr.fln("void*[{}] bindPtrs;",mapper.obj.bindableFieldCount);
		wr.fln("BindInfo bindInfo;");
		wr.fln("uint idx = 0;");

		foreach(field; mapper.mappings)
		{
			wr.fln("if({}) {{ fields[idx] = {}; ++idx;}", field.isModifiedExpr, DQuote(field.colname));
		}
		
		wr.fln("bindInfo.types = setBindTypes(fields[0..idx], bindTypes);");
		wr.fln("bindInfo.ptrs = setBindPtrs(fields[0..idx], bindPtrs);");
		
		wr.fln("if(id_) {{");
		wr.indent;
		
		wr.fln("static if(is(typeof(this.beforeUpdate))) if(!this.beforeUpdate) return false;");
		
		
		wr.fln(`auto res = db.update({}, fields[0..idx], "WHERE id = ?", bindInfo, id_);`,
				DQuote(mapper.schema.tablename));
		
		wr.fln(`if(db.affectedRows == 1) return true; else return false;`);
		
		wr.fln("static if(is(typeof(this.afterUpdate))) this.afterUpdate;");
		
		wr.dedent;
		wr.fln("}");
		
		wr.fln("else {{");
		wr.indent;
		
		wr.fln("static if(is(typeof(this.beforeCreate))) if(!this.beforeCreate) return false;");
		
		wr.fln("auto res = db.insert({}, fields[0..idx], bindInfo);",
			DQuote(mapper.schema.tablename));
		
		wr.fln("id_ = db.lastInsertID;");
			
		wr.fln(`if(id_) return true; else return false;`);
		
		wr.fln("static if(is(typeof(this.afterCreate))) this.afterCreate;");
		
		wr.dedent;
		wr.fln("}");
		
		wr.fln("static if(is(typeof(this.afterSave))) this.afterSave;");
		
		wr.dedent;
		wr("}").nl;
		wr.nl;
	}
}