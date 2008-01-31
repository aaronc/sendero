module sendero.routing.Convert;

static import tango.util.Convert;
import tango.group.time;

//static import sendero.util.Convert;
import sendero.routing.Common;
import sendero.conversion.Conversion;

/+interface IConverter(T)
{
	bool convert(Param, inout T);
	char[] getFormatString();
}+/

template ConvClassParam(char[] n) {
	const char[] ConvClassParam = "static if(val.tupleof.length > " ~ n ~ ") {"
		"pp = val.tupleof[" ~ n ~ "].stringof[4 .. $] in param.obj;"
		"if(pp) {"
			"static if(is(typeof(T.convert!(typeof(val.tupleof[" ~ n ~ "]))))) {"
				"T.convert(*pp, val.tupleof[" ~ n ~ "]);"
			"}"
			"else {"
				"convertParam!(typeof(val.tupleof[" ~ n ~ "]), Req)(val.tupleof[" ~ n ~ "], *pp);"
			"}"
		"}"
	"}";
}

void convertParam(T, Req)(inout T val, Param param)
{
	static if(is(typeof(tango.util.Convert.to!(T, char[]))))
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
			return;
		}
		else val = to!(T)(param.val);
	}
	else static if(is(T == bool))
	{
		val = param.type != Param.None ? true : false;  
	}
	else static if(is(typeof(Convert!(T))))
	{
		
	}
	else static if(is(T == DateTime) || is(T == Time))
	{
		
	}
	else static if(is(T == class) || is(T == struct))
	{
		if(param.obj.length == 0) {
			val = T.init;
			return;
		}
		
		static if(is(T == class))
			val = new T;
		
		Param* pp;
		
		/+static if(val.tupleof.length > 0) {
			pp = val.tupleof[0].stringof[4 .. $] in param.obj;
			static if(is(typeof(T.convert!( typeof(val.tupleof[0]) )()) == bool)) {
				T.convert(*pp, val.tupleof[0]);
			}
			else {
				if(pp) convertParam!(typeof(val.tupleof[0]), Req)(val.tupleof[0], *pp);
			}
		};+/
		
		mixin(ConvClassParam!("0"));
		mixin(ConvClassParam!("1"));
		mixin(ConvClassParam!("2"));
		mixin(ConvClassParam!("3"));
		mixin(ConvClassParam!("4"));
		mixin(ConvClassParam!("5"));
		mixin(ConvClassParam!("6"));
		mixin(ConvClassParam!("7"));
		mixin(ConvClassParam!("8"));
		mixin(ConvClassParam!("9"));
		mixin(ConvClassParam!("10"));
		mixin(ConvClassParam!("11"));
		mixin(ConvClassParam!("12"));
		mixin(ConvClassParam!("13"));
		mixin(ConvClassParam!("14"));
		mixin(ConvClassParam!("15"));
	}
	else static if(is(T == char[][]))
	{
		switch(param.type)
		{
		case ParamT.Value:
			val = null;
			val ~= param.val;
			break;
		case ParamT.Array:
			val = param.arr;
			break;
		default:
			val = null;
			break;
		}		
	}
	/+else if(Convert!(T).converter !is null)
	{
		
	}+/
/+	else
	{
		if(param.type != ParamT.Value) {
			debug assert(false);
			val = T.init;
			return;
		}
			
		sendero.util.Convert.fromString(param.val, val);
	}+/
}

template ConvertParam(char[] n) {
	const char[] ConvertParam = "static if(P.length > " ~ n ~ ") {"
		"pParam = paramNames[" ~ n ~ " - offset] in params;"
		"if(pParam) {"
			"convertParam!(P[" ~ n ~ "], Req)(p[" ~ n ~ "], *pParam);"
		"}"
		"else p[" ~ n ~ "] = P[" ~ n ~ "].init;"
	"}";
}

void convertParams(Req, P...)(Req req, char[][] paramNames, inout P p)
{
	auto params = req.params;
	
	Param* pParam;
		
	uint offset = 0;
	
	static if(P.length > 0) {
		static if(is(P[0] == Req))
		{
			offset = 1;
			p[0] = req;
		}
		else
		{
			pParam = paramNames[0] in params;
			if(pParam) {
				convertParam!(P[0], Req)(p[0], *pParam);
			}
			else p[0] = P[0].init;
		}
	}
	
	if(paramNames.length < P.length - offset)
		throw new Exception("Incorrect number of parameters: " ~ P.stringof);
	
	mixin(ConvertParam!("1"));
	mixin(ConvertParam!("2"));
	mixin(ConvertParam!("3"));
	mixin(ConvertParam!("4"));
	mixin(ConvertParam!("5"));
	mixin(ConvertParam!("6"));
	mixin(ConvertParam!("7"));
	mixin(ConvertParam!("8"));
	mixin(ConvertParam!("9"));
	mixin(ConvertParam!("10"));
	mixin(ConvertParam!("11"));
	mixin(ConvertParam!("12"));
	mixin(ConvertParam!("13"));
	mixin(ConvertParam!("14"));
	mixin(ConvertParam!("15"));
}
