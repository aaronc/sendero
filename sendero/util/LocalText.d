module sendero.util.LocalText;

import sendero.util.ExecutionContext;
import sendero.util.StringCharIterator;

public import mango.icu.ULocale;

import mango.icu.UMessageFormat;
import mango.icu.UCalendar;
import mango.icu.UString;
import mango.icu.UNumberFormat;
import mango.icu.UDateFormat;

import Integer = tango.text.convert.Integer;
import Utf = tango.text.convert.Utf;
import Text = tango.text.Util;
import tango.core.Traits;

const ubyte FORMAT_TIME = 0;
const ubyte FORMAT_DATE= 1;
const ubyte FORMAT_NUMBER = 2;
const ubyte FORMAT_CHOICE = 3;
const ubyte FORMAT_SPELLOUT = 4;
const ubyte FORMAT_ORDINAL = 5;
const ubyte FORMAT_DURATION = 6;
const ubyte FORMAT_STRING = 7;
const ubyte FORMAT_DATETIME = 8;

const ubyte DATE_STYLE_SHORT = 0;
const ubyte DATE_STYLE_MEDIUM = 1;
const ubyte DATE_STYLE_LONG = 2;
const ubyte DATE_STYLE_FULL = 3;
const ubyte DATE_STYLE_CUSTOM = 4;

const ubyte NUMBER_STYLE_CURRENCY = 0;
const ubyte NUMBER_STYLE_PERCENT = 1;
const ubyte NUMBER_STYLE_INTEGER = 2;
const ubyte NUMBER_STYLE_SCIENTIFIC = 3;
const ubyte NUMBER_STYLE_CUSTOM = 4;

enum ParamT : ubyte { Var, Func };

package class Param
{
	ushort offset;
	ushort index;
	Expression expr;
	ubyte elementFormat;
	ubyte secondaryFormat;
	char[] formatString;
}

interface IMessage
{
	bool plural();
	char[] exec(ExecutionContext ctxt);
}

package class Message : IMessage
{
	char[] msg;
	Param[] params;
	bool plural() {return false;}
	
	char[] exec(ExecutionContext ctxt)
	{
		uint idx = 0;
		char[] o;
		foreach(p; params)
		{			
			o ~= msg[idx .. p.offset];
			idx = p.offset;
		
			auto lcl = ctxt.locale;
			auto tz = ctxt.timezone;
			
			auto var = p.expr.exec(ctxt);
			
			switch(var.type)
			{
			case(VarT.Bool):
				auto x = var.data.get!(bool);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.Byte):
				auto x = var.data.get!(byte);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.Short):
				auto x = var.data.get!(short);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.Int):
				auto x = var.data.get!(int);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.Long):
				auto x = var.data.get!(long);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.UByte):
				auto x = var.data.get!(ubyte);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.UShort):
				auto x = var.data.get!(ushort);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.UInt):
				auto x = var.data.get!(uint);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.ULong):
				auto x = var.data.get!(ulong);
				o ~= renderLong(x, p, lcl);
				break;
			case(VarT.Float):
				auto x = var.data.get!(float);
				o ~= renderDouble(x, p, lcl);
				break;
			case(VarT.Double):
				auto x = var.data.get!(float);
				o ~= renderDouble(x, p, lcl);
				break;
			case(VarT.String):
				auto x = var.data.get!(char[]);
				o ~= x;
				break;
			case(VarT.DateTime):
				auto x = var.data.get!(DateTime);
				o ~= renderDateTime(x, p, lcl, tz);
				break;
			case(VarT.Date):
				auto x = var.data.get!(Date);
				auto dt = DateTime(x.year, x.month, x.day);
				dt.addHours(x.hour);
				dt.addMinutes(x.min);
				dt.addSeconds(x.sec);
				o ~= renderDateTime(dt, p, lcl, tz);
				break;
			case(VarT.Time):
				auto x = var.data.get!(Time);
				o ~= renderDateTime(DateTime(x), p, lcl, tz);
				break;
			default:
				break;
			}
			
			
		}
		if(idx < msg.length) o ~= msg[idx .. $];
		return o;
	}
	
	static char[] renderLong(long x, inout Param p, ULocale lcl = ULocale.US)
	{
		UNumberFormat fmt;
		
		switch(p.elementFormat)
		{
		case FORMAT_SPELLOUT:
			fmt = new USpelloutFormat(lcl);
			break;
		case FORMAT_ORDINAL:
			fmt = new UNumberFormat(UNumberFormat.Style.Ordinal, null, lcl);
			break;
		case FORMAT_DURATION:
			fmt = new UDurationFormat(lcl);
			break;
		case FORMAT_NUMBER:
			switch(p.secondaryFormat)
			{
			case NUMBER_STYLE_PERCENT:
				fmt = new UPercentFormat(lcl);
				break;
			case NUMBER_STYLE_SCIENTIFIC:
				fmt = new UScientificFormat(lcl);
				break;
			case NUMBER_STYLE_INTEGER:
				fmt = new UDecimalFormat(lcl);
				break;
			}
			break;
		default:
			fmt = new UDecimalFormat(lcl);
			break;
		}
		
		auto dst = new UString(100);
		fmt.format(dst, x);
		return dst.toUtf8;
	}
	
	static char[] renderDouble(double x, inout Param p, ULocale lcl = ULocale.US)
	{
		UNumberFormat fmt;
		
		if(p.secondaryFormat == NUMBER_STYLE_SCIENTIFIC) {
			fmt = new UScientificFormat(lcl);
		}
		else {
			fmt = new UDecimalFormat(lcl);
		}
		
		auto dst = new UString(100);
		fmt.format(dst, x);
		return dst.toUtf8;
	}
	
	static char[] renderDateTime(inout DateTime dt, inout Param p, ULocale lcl = ULocale.US, UTimeZone tz = UTimeZone.Default)
	{
		UDateFormat udf;
		switch(p.elementFormat)
		{
		case FORMAT_DATE:
			switch(p.secondaryFormat)
			{
			case DATE_STYLE_SHORT:
				udf = new UDateFormat(UDateFormat.Style.None, UDateFormat.Style.Short, lcl, tz);
				break;
			case DATE_STYLE_LONG:
				udf = new UDateFormat(UDateFormat.Style.None, UDateFormat.Style.Long, lcl, tz);
				break;
			case DATE_STYLE_FULL:
				udf = new UDateFormat(UDateFormat.Style.None, UDateFormat.Style.Full, lcl, tz);
				break;
			case DATE_STYLE_CUSTOM:
				auto pat = new UString(Utf.toUtf16(p.formatString));
				udf = new UDateFormat(UDateFormat.Style.None, UDateFormat.Style.Default, lcl, tz, pat);
				break;
			case DATE_STYLE_MEDIUM:
			default:
				udf = new UDateFormat(UDateFormat.Style.None, UDateFormat.Style.Medium, lcl, tz);
				break;
			}
			break;
			
		case FORMAT_TIME:
			switch(p.secondaryFormat)
			{
			case DATE_STYLE_SHORT:
				udf = new UDateFormat(UDateFormat.Style.Short, UDateFormat.Style.None, lcl, tz);
				break;
			case DATE_STYLE_LONG:
				udf = new UDateFormat(UDateFormat.Style.Long, UDateFormat.Style.None, lcl, tz);
				break;
			case DATE_STYLE_FULL:
				udf = new UDateFormat(UDateFormat.Style.Full, UDateFormat.Style.None, lcl, tz);
				break;
			case DATE_STYLE_CUSTOM:
				auto pat = new UString(Utf.toUtf16(p.formatString));
				udf = new UDateFormat(UDateFormat.Style.Default, UDateFormat.Style.None, lcl, tz, pat);
				break;
			case DATE_STYLE_MEDIUM:
			default:
				udf = new UDateFormat(UDateFormat.Style.Medium, UDateFormat.Style.None, lcl, tz);
				break;
			}
			break;
		
		case FORMAT_DATETIME:
		default:
			switch(p.secondaryFormat)
			{
			case DATE_STYLE_SHORT:
				udf = new UDateFormat(UDateFormat.Style.Short, UDateFormat.Style.Short, lcl, tz);
				break;
			case DATE_STYLE_LONG:
				udf = new UDateFormat(UDateFormat.Style.Long, UDateFormat.Style.Long, lcl, tz);
				break;
			case DATE_STYLE_FULL:
				udf = new UDateFormat(UDateFormat.Style.Full, UDateFormat.Style.Full, lcl, tz);
				break;
			case DATE_STYLE_CUSTOM:
				auto pat = new UString(Utf.toUtf16(p.formatString));
				udf = new UDateFormat(UDateFormat.Style.Default, UDateFormat.Style.Default, lcl, tz, pat);
				break;
			case DATE_STYLE_MEDIUM:
			default:
				udf = new UDateFormat(UDateFormat.Style.Medium, UDateFormat.Style.Medium, lcl, tz);
				break;
			}
			break;
		}
		
		auto dst = new UString(100);
		UCalendar.UDate udat = cast(UCalendar.UDate)((dt.ticks - 621355788e9) / 1e4);
		udf.format(dst, udat);
		return dst.toUtf8;
	}
}

package class PluralMessage : IMessage
{
	Message[] pluralForms;
	char[] pluralVariable;
	bool plural() {return true;}
	
	char[] exec(ExecutionContext ctxt)
	{
		auto v = ctxt.getVar(pluralVariable);
		
		assert(false, "PluralMessage not implemented yet");
		
		return null;
	}
}


/*
 * {$varName}
 * {$varName, elementFormat}
 * 
 *  elementFormat := "time" { "," datetimeStyle }
                      | "date" { "," datetimeStyle }
                      | "datetime" { "," datetimeStyle }
                      | "number" { "," numberStyle }
                      | "choice" "," choiceStyle
                      | "spellout"
                      | "ordinal"
                      | "duration"

       datetimeStyle := "short"
                      | "medium"
                      | "long"
                      | "full"
                      | dateFormatPattern

       numberStyle :=   "currency"
                      | "percent"
                      | "integer"
                      | numberFormatPattern

       choiceStyle :=   choiceFormatPattern
 */

class MessageParserException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
} 

public void parseExpression(char[] msg, inout Expression expr, FunctionBindingContext ctxt)
{
	scope itr = new StringCharIterator!(char)(msg);
	if(itr[0] == '$') {
		//throw new MessageParserException("Expected $ before variable name"); //TODO throw exception here?
		++itr;
		char[] var;
		while(itr.good && itr[0] != ',' && itr[0] != '}')
		{
			var ~= itr[0];
			++itr;
		}
		expr.var = VarPath(var);
		expr.type = ExpressionT.Var;
	}
	else {	
		void parseFuncParams(char[] str)
		{
			auto params = Text.split(str, ",");
			foreach(x; params)
			{
				Expression fParam;
				if(x[0] == '$')
				{
					fParam.type = ExpressionT.Var;
					fParam.var = VarPath(x[1 .. $]);
				}
				else
				{
					fParam.type = ExpressionT.Value;
					fParam.val.data = x;
					fParam.val.type = VarT.String;
				}
				expr.func.params ~= fParam;
			}
		}
		
		uint i = itr.location;
		if(!itr.forwardLocate('(')) throw new MessageParserException("Expected ( after function name");
		uint j = itr.location;
		char[] name = itr.randomAccessSlice(i, j);
		auto fn = ctxt.getFunction(name);
		if(!fn)  new MessageParserException("Unable to find definition of function " ~ name); 
		expr.func.func = fn;
		i = j + 1;
		if(!itr.forwardLocate(')')) throw new MessageParserException("Expected ) after function params");
		j = itr.location;
		parseFuncParams(itr.randomAccessSlice(i, j));
		++itr;
		expr.type = ExpressionT.FuncCall;
	}
}

public Message parseMessage(char[] msg, FunctionBindingContext ctxt)
{
	auto itr = new StringCharIterator!(char)(msg);
	
	Param parseParam(uint offset)
	{
		Param unexpectedFormat() {
			throw new MessageParserException("Unexpected ElementFormat in message format string"); //TODO throw exception here?
			return null;
		}
		
		auto p = new Param;		
		p.offset = offset;
		
		uint i = itr.location;
		if(!itr.forwardLocate('}')) throw new MessageParserException("Expected \'}\' at end of expression");
		uint j = itr.location;
		char[] exprTxt = itr.randomAccessSlice(i, j);		
		j = Text.locate(exprTxt, ':');
		parseExpression(exprTxt[0 .. j], p.expr, ctxt);
		itr.seek(i + j);	
		
		if(!itr.good)
			return null;
		else if(itr[0] == '}') {
			++itr;
			p.elementFormat = FORMAT_STRING;
			return p;
		}
		
		++itr;
		
		if(itr[0] == ' ') ++itr;
				
		switch(itr[0])
		{
		case 't':
			if(itr[0 .. 4] == "time") {
				itr += 4;
				p.elementFormat = FORMAT_TIME;
			}
			else return unexpectedFormat();
			break;
		case 'd':
			if(itr[0 .. 4] == "date") {
				itr += 4;
				if(itr[0 .. 4] == "time") {
					itr += 4;
					p.elementFormat = FORMAT_DATETIME;
				}
				else p.elementFormat = FORMAT_DATE;
			}
			else if(itr[0 .. 8] == "duration") {
				itr += 7;
				p.elementFormat = FORMAT_DURATION;
			}
			else return unexpectedFormat();
			break;
		case 'n':
			if(itr[0 .. 5] == "number") {
				itr += 5;
				p.elementFormat = FORMAT_NUMBER;
			}
			else return unexpectedFormat();
			break;
		case 'c':
			if(itr[0 .. 5] == "choice") {
				itr += 5;
				p.elementFormat = FORMAT_CHOICE;
			}
			else return unexpectedFormat();
			break;
		case 's':
			if(itr[0 .. 8] == "spellout") {
				itr += 8;
				p.elementFormat = FORMAT_SPELLOUT;
			}
			else return unexpectedFormat();
			break;
		case 'o':
			if(itr[0 .. 7] == "ordinal") {
				itr += 7;
				p.elementFormat = FORMAT_ORDINAL;
			}
			else return unexpectedFormat();
			break;
		default:
			return unexpectedFormat();
			break;
		}
		
		Param parseStyle() {
			while(itr.good) {
				if(itr[0] == '}') {
					++itr;
					return p;
				}
				p.formatString ~= itr[0];
				++itr;
			}
			return null;
		}
		
		Param parseEnd() {
			if(itr[0] == ' ') ++itr;
			if(itr[0] != '}')
				return null;
			else {
				++itr;
				return p;
			}
		}
		
		Param parseDateStyle() {	
			switch(itr[0]) {
			case 's':
				if(itr[0 .. 5] == "short") {
					itr += 5;
					p.elementFormat = DATE_STYLE_SHORT;
				}
				else return unexpectedFormat();
				break;
			case 'm':
				if(itr[0 .. 6] == "medium") {
					itr += 6;
					p.secondaryFormat = DATE_STYLE_MEDIUM;
				}
				else return unexpectedFormat();
				break;
			case 'l':
				if(itr[0 .. 4] == "long") {
					itr += 4;
					p.secondaryFormat = DATE_STYLE_LONG;
				}
				else return unexpectedFormat();
				break;
			case 'f':
				if(itr[0 .. 4] == "full") {
					itr += 4;
					p.secondaryFormat = DATE_STYLE_FULL;
				}
				else return unexpectedFormat();
				break;
			default:
				p.secondaryFormat = DATE_STYLE_CUSTOM;
				return parseStyle();
			}
			return parseEnd();
		}
		
		Param parseNumberStyle() {
			switch(itr[0]) {
			case 'c':
				if(itr[0 .. 8] == "currency") {
					itr += 8;
					p.secondaryFormat = NUMBER_STYLE_CURRENCY;
				}
				else return unexpectedFormat();
				break;
			case 'p':
				if(itr[0 .. 7] == "percent") {
					itr += 7;
					p.secondaryFormat = NUMBER_STYLE_PERCENT;
				}
				else return unexpectedFormat();
				break;
			case 'i':
				if(itr[0 .. 7] == "integer") {
					itr += 7;
					p.secondaryFormat = NUMBER_STYLE_INTEGER;
				}
				else return unexpectedFormat();
				break;
			default:
				p.secondaryFormat = NUMBER_STYLE_CUSTOM;
				return parseStyle();
			}
			return parseEnd();
		}
		
		switch(itr[0]) {			
		case ',':
			++itr;
			if(itr[0] == ' ') ++itr;
			switch(p.elementFormat) {
			case FORMAT_DATE:
			case FORMAT_TIME:
			case FORMAT_DATETIME:
				return parseDateStyle();
			case FORMAT_NUMBER:
				return parseNumberStyle();
			default:
				return parseStyle();
			}
			break;
		case '}':
			++itr;
			return p;
		default:
			return unexpectedFormat();
		}
	}
	
	char[] res;
	Param[] params;
	
	while(itr.good)
	{
		switch(itr[0])
		{
/*		case '{':
			if(itr[1] == '{') {
				itr += 2;
				res ~= '{';
			}
			else {
				++itr;
				auto p = parseParam(res.length);
				params ~= p;
			}*/
		case '_':
			if(itr[1] == '{') {
				if(itr[2] == '{') {
					itr += 3;
					res ~= "_{";
				}
				else {
					itr += 2;
					auto p = parseParam(res.length);
					params ~= p;
				}
			}
			else {
				res ~= '$';
				++itr;
			}
			break;
		default:
			res ~= itr[0];
			++itr;
			break;
		}		
	}
	
	auto m = new Message;
	m.msg = res;
	m.params = params;
	return m;
}

version(Unittest)
{
	import tango.io.Stdout;
}

unittest
{
	auto funcCtxt = new FunctionBindingContext;
	auto m = parseMessage("Hello _{$word} world, the only _{$num: spellout}!", funcCtxt);
	assert(m.msg == "Hello  world, the only !");
	assert(m.params.length == 2);
	assert(m.params[0].elementFormat == FORMAT_STRING);
	assert(m.params[0].expr.var[0] == "word", m.params[0].expr.var[0]);
	assert(m.params[1].elementFormat == FORMAT_SPELLOUT);
	assert(m.params[1].expr.var[0] == "num", m.params[1].expr.var[0]);

	auto ctxt = new ExecutionContext;
	int x = 1;
	ctxt.addVar("num", x);
	ctxt.addVar("word", "beautiful");
	auto res = m.exec(ctxt);
	assert(res == "Hello beautiful world, the only one!", res);
}