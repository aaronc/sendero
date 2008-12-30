/* 
 * DO NOT EDIT THIS FILE!
 *
 * This file was generated by the DecoratedD precompiler.
 * Any changes you make to this file will be modified the
 * next time you run DecoratedD.  If you would like to make
 * changes to this file, modify either the source file that
 * was used to generate this file, or the Decorator library
 * that was called by DecoratedD to generate this output.
 *
 */

#line 1 "test/senderoxc/test2.sdx"
module test2;#line 15 "test/senderoxc/mysql/test2.d"



import sendero_base.Core, sendero.db.Bind, sendero.vm.Bind, sendero.validation.Validations;
import sendero.db.DBProvider;
import sendero.http.Request, sendero.routing.Convert;
import sendero.core.Memory;
import sendero.util.collection.StaticBitArray, sendero.util.Singleton;

#line 1 "test/senderoxc/test2.sdx"


/+@data+/ class Posting#line 28 "test/senderoxc/mysql/test2.d"

: IObject, IHttpSet
#line 3 "test/senderoxc/test2.sdx"

{
	/+@autoPrimaryKey("id")+/;

	/+@hasOne("User", "author")+/;
	/+@String("entry")+/;
	/+@Time("created")+/;
	/+@Time("modified")+/;
	
	/+@required+/ /+@String("title")+/;
	
	/+@String("tags")+/;
#line 44 "test/senderoxc/mysql/test2.d"


bool validate()
{
	bool succeed = true;

	void fail(char[] field, Error err)	{
		succeed = false;
		__errors__.add(field, err);
	}

	if(!ExistenceValidation!(char[]).validate(title_)) fail("title_", ExistenceValidation!(char[]).error);

	return succeed;
}


mixin SessionAllocate!();

ErrorMap errors()
{
	return __errors__;
}
void clearErrors()
{
	__errors__.reset;
}
private ErrorMap __errors__;
alias DefaultMysqlProvider db;
public void destroy()
{
	const char[] deleteSql = "DELETE FROM `Posting` WHERE `id` = ?";
	scope st = db.prepare(deleteSql);
	st.execute(id);
}

bool save()
{
	auto db = getDb;
	char[][6] fields;
	BindType[6] bindTypes;
	void*[6] bindPtrs;
	BindInfo bindInfo;
	uint idx = 0;
	if(__touched__[0]) {malformed format}) { fields[idx] = "entry"; ++idx;}
	if(__touched__[1]) {malformed format}) { fields[idx] = "created"; ++idx;}
	if(__touched__[2]) {malformed format}) { fields[idx] = "modified"; ++idx;}
	if(__touched__[3]) {malformed format}) { fields[idx] = "title"; ++idx;}
	if(__touched__[4]) {malformed format}) { fields[idx] = "tags"; ++idx;}
	if(id_) { fields[idx] = "id"; ++idx; }
	bindInfo.types = setBindTypes(fields[0..idx], bindTypes);
	bindInfo.ptrs = setBindPtrs(field[0..idx], bindPtrs);
	if(id_) {
		auto res = db.update("Posting", fields[0..idx], "WHERE id = ?", bindInfo);
		if(db.affectedRows == 1) return true; else return false;
	}}
	else {
		auto res = db.insert("Posting", fields[0..idx], bindInfo);
		id_ = db.lastInsertID;
		if(id_) return true; else return false;
	}}
}

Var opIndex(char[] key)
{
	Var res;
	switch(key)
	{
		case "entry": bind(res, entry()); break;
		case "created": bind(res, created()); break;
		case "modified": bind(res, modified()); break;
		case "title": bind(res, title()); break;
		case "tags": bind(res, tags()); break;
		default: return Var();
	}
	return res;
}
int opApply (int delegate (inout char[] key, inout Var val) dg)
{
	int res; char[] key; Var val;
	key = "entry"; bind(val, entry()); if((res = dg(key, val)) != 0) return res;
	key = "created"; bind(val, created()); if((res = dg(key, val)) != 0) return res;
	key = "modified"; bind(val, modified()); if((res = dg(key, val)) != 0) return res;
	key = "title"; bind(val, title()); if((res = dg(key, val)) != 0) return res;
	key = "tags"; bind(val, tags()); if((res = dg(key, val)) != 0) return res;
	return res;
}
void opIndexAssign(Var val, char[] key) {}
Var opCall(Var[] params, IExecContext ctxt) { return Var(); }
void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) {}


protected StaticBitArray!(1,5) __touched__;


void httpSet(IObject obj, Request req)
{
	foreach(key, val; obj)
	{
		switch(key)
		{
			case "entry": entry_ = convertParam!(char[], Req)(val, req); break;
			case "created": created_ = convertParam!(Time, Req)(val, req); break;
			case "modified": modified_ = convertParam!(Time, Req)(val, req); break;
			case "title": title_ = convertParam!(char[], Req)(val, req); break;
			case "tags": tags_ = convertParam!(char[], Req)(val, req); break;
			default: break;
		}
	}
}

BindType[] setBindTypes(char[][] fieldNames, BindType[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class Posting");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = BindType.String; break;
		case "created": dst[i] = BindType.Time; break;
		case "modified": dst[i] = BindType.Time; break;
		case "title": dst[i] = BindType.String; break;
		case "tags": dst[i] = BindType.String; break;
		}
		++idx;
	}
	return dst[0..idx];
}
void*[] setBindPtrs(char[][] fieldNames, void*[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class Posting");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = &this.entry_; break;
		case "created": dst[i] = &this.created_; break;
		case "modified": dst[i] = &this.modified_; break;
		case "title": dst[i] = &this.title_; break;
		case "tags": dst[i] = &this.tags_; break;
		}
		++idx;
	}
	return dst[0..idx];
}
ptrdiff_t[] setBindPtrs(char[][] fieldNames, ptrdiff_t[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class Posting");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = &this.entry_ - &this; break;
		case "created": dst[i] = &this.created_ - &this; break;
		case "modified": dst[i] = &this.modified_ - &this; break;
		case "title": dst[i] = &this.title_ - &this; break;
		case "tags": dst[i] = &this.tags_ - &this; break;
		}
		++idx;
	}
	return dst[0..idx];
}

public char[] entry() { return entry_; }
public void entry(char[] val) {__touched__[0] = true; entry_ = val;}
private char[] entry_;

public Time created() { return created_; }
public void created(Time val) {__touched__[1] = true; created_ = val;}
private Time created_;

public Time modified() { return modified_; }
public void modified(Time val) {__touched__[2] = true; modified_ = val;}
private Time modified_;

public char[] title() { return title_; }
public void title(char[] val) {__touched__[3] = true; title_ = val;}
private char[] title_;

public char[] tags() { return tags_; }
public void tags(char[] val) {__touched__[4] = true; tags_ = val;}
private char[] tags_;
public uint id() {return id_;}
private uint id_;

public User author() {return author_;}
public void author(User val) {__touched__[0] = true; author_ = val;}
private HasOne!(User) author_;


#line 15 "test/senderoxc/test2.sdx"
}

/+@data+/ class BlogEntry : Posting#line 235 "test/senderoxc/mysql/test2.d"

, IObject, IHttpSet
#line 17 "test/senderoxc/test2.sdx"

{
	
#line 242 "test/senderoxc/mysql/test2.d"


bool validate()
{
	bool succeed = true;

	void fail(char[] field, Error err)	{
		succeed = false;
		__errors__.add(field, err);
	}


	return succeed;
}


mixin SessionAllocate!();

ErrorMap errors()
{
	return __errors__;
}
void clearErrors()
{
	__errors__.reset;
}
private ErrorMap __errors__;
alias DefaultMysqlProvider db;
bool save()
{
	auto db = getDb;
	char[][1] fields;
	BindType[1] bindTypes;
	void*[1] bindPtrs;
	BindInfo bindInfo;
	uint idx = 0;
	if(id_) { fields[idx] = "id"; ++idx; }
	bindInfo.types = setBindTypes(fields[0..idx], bindTypes);
	bindInfo.ptrs = setBindPtrs(field[0..idx], bindPtrs);
	if(id_) {
		auto res = db.update("Posting", fields[0..idx], "WHERE id = ?", bindInfo);
		if(db.affectedRows == 1) return true; else return false;
	}}
	else {
		auto res = db.insert("Posting", fields[0..idx], bindInfo);
		id_ = db.lastInsertID;
		if(id_) return true; else return false;
	}}
}

Var opIndex(char[] key)
{
	Var res;
	switch(key)
	{
		default: return Var();
	}
	return res;
}
int opApply (int delegate (inout char[] key, inout Var val) dg)
{
	int res; char[] key; Var val;
	return res;
}
void opIndexAssign(Var val, char[] key) {}
Var opCall(Var[] params, IExecContext ctxt) { return Var(); }
void toString(IExecContext ctxt, void delegate(char[]) utf8Writer, char[] flags = null) {}



void httpSet(IObject obj, Request req)
{
	foreach(key, val; obj)
	{
		switch(key)
		{
			default: break;
		}
	}
}

BindType[] setBindTypes(char[][] fieldNames, BindType[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class BlogEntry");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = BindType.String; break;
		case "created": dst[i] = BindType.Time; break;
		case "modified": dst[i] = BindType.Time; break;
		case "title": dst[i] = BindType.String; break;
		case "tags": dst[i] = BindType.String; break;
		}
		++idx;
	}
	return dst[0..idx];
}
void*[] setBindPtrs(char[][] fieldNames, void*[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class BlogEntry");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = &this.entry_; break;
		case "created": dst[i] = &this.created_; break;
		case "modified": dst[i] = &this.modified_; break;
		case "title": dst[i] = &this.title_; break;
		case "tags": dst[i] = &this.tags_; break;
		}
		++idx;
	}
	return dst[0..idx];
}
ptrdiff_t[] setBindPtrs(char[][] fieldNames, ptrdiff_t[] dst)
{
	assert(dst.length >= 5, "Must provide an array of at least length 5 to bind items to class BlogEntry");
	size_t idx = 0;
	foreach(name;fieldNames) {
		switch(name) {
		case "entry": dst[i] = &this.entry_ - &this; break;
		case "created": dst[i] = &this.created_ - &this; break;
		case "modified": dst[i] = &this.modified_ - &this; break;
		case "title": dst[i] = &this.title_ - &this; break;
		case "tags": dst[i] = &this.tags_ - &this; break;
		}
		++idx;
	}
	return dst[0..idx];
}

#line 20 "test/senderoxc/test2.sdx"
}