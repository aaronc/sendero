/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.vm.LocalText;

//import sendero.vm.ExecutionContext;
import sendero.xml.XPath;
import sendero.vm.Expression;
//import sendero.util.FunctionBindingContext;
import sendero_base.util.StringCharIterator;

version(ICU) {
	public import mango.icu.ULocale;
	import mango.icu.UMessageFormat;
	import mango.icu.UCalendar;
	import mango.icu.UString;
	import mango.icu.UNumberFormat;
	import mango.icu.UDateFormat;
}
else {
	import Float = tango.text.convert.Float;
	import tango.text.locale.Convert;
	import tango.text.locale.Core;
	import sendero.time.Format;
}

import tango.group.time;
import Integer = tango.text.convert.Integer;
import Utf = tango.text.convert.Utf;
import Text = tango.text.Util;
import tango.core.Traits;

/*
 * {$varName}
 * {$varName: elementFormat}
 * {functionName(parameters)}
 * {functionName(parameters): elementFormat}
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

package class Param
{
	ushort offset;
	ushort index;
	IExpression expr;
	ubyte elementFormat;
	ubyte secondaryFormat;
	char[] formatString;
}

interface IMessage
{
	char[] exec(IObject ctxt);
}

class Message : IMessage
{
	char[] msg;
	Param[] params;
	bool plural() {return false;}
	
	static char[] renderParam(IObject ctxt, inout Var var)
	{
		scope p = new Param;
		return renderParam(ctxt, var, p);
	}
	
	static char[] renderParam(IObject ctxt, inout Var var, Param p)
	{
		char[] o;
		auto lcl = ctxt.locale;
		auto tz = ctxt.timezone;
		
		switch(var.type)
		{
		case(VarT.Bool):
			auto x = var.bool_;
			o ~= renderLong(x, p, lcl);
			break;
		case(VarT.Long):
			auto x = var.long_;
			o ~= renderLong(x, p, lcl);
			break;
		case(VarT.Double):
			auto x = var.double_;
			o ~= renderDouble(x, p, lcl);
			break;
		case(VarT.String):
			auto x = var.string_;
			o ~= x;
			break;
		case(VarT.DateTime):
			auto x = var.dateTime_;
			o ~= renderDateTime(x, p, lcl, tz);
			break;
		default:
			break;
		}
		return o;
	}
	
	char[] exec(IObject ctxt)
	{
		uint idx = 0;
		char[] o;
		foreach(p; params)
		{			
			o ~= msg[idx .. p.offset];
			idx = p.offset;
			
			auto var = p.expr.exec(ctxt);
			
			o ~= renderParam(ctxt, var, p);		
		}
		if(idx < msg.length) o ~= msg[idx .. $];
		return o;
	}
	
	static char[] renderLong(long x, inout Param p, Locale lcl)
	{
		version(ICU) {
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
			return dst.toString;
		}
		else {
			return Integer.toString(x);
		}
	}
	
	static char[] renderDouble(double x, inout Param p, Locale lcl)
	{
		version(ICU) {
			UNumberFormat fmt;
			
			if(p.secondaryFormat == NUMBER_STYLE_SCIENTIFIC) {
				fmt = new UScientificFormat(lcl);
			}
			else {
				fmt = new UDecimalFormat(lcl);
			}
			
			auto dst = new UString(100);
			fmt.format(dst, x);
			return dst.toString;
		}
		else {
			return Float.toString(x);
		}
	}
	
	static char[] renderDateTime(inout Time t, inout Param p, Locale lcl, Timezone tz)
	{
		version(ICU) {
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
			//UCalendar.UDate udat = cast(UCalendar.UDate)((t.ticks - 621355788e9) / 1e4);
			UCalendar.UDate udat = cast(UCalendar.UDate)((t.ticks - Time.epoch1970) / 1e4);
			udf.format(dst, udat);
			return dst.toString;
		}
		else {
			//char[] res;
			//res.length = 100;
			char[200] res = void;
			switch(p.elementFormat)
			{
			case FORMAT_DATE:
				switch(p.secondaryFormat)
				{
				case DATE_STYLE_CUSTOM:
					return formatDateTime(res, t, p.formatString);
				case DATE_STYLE_SHORT:
					return formatDateTime(res, t, "d");
				case DATE_STYLE_LONG:
				case DATE_STYLE_FULL:
				case DATE_STYLE_MEDIUM:
				default:
					return formatDateTime(res, t, "D");
				}
				break;
				
			case FORMAT_TIME:
				switch(p.secondaryFormat)
				{
				case DATE_STYLE_CUSTOM:
					return formatDateTime(res, t, p.formatString);
				case DATE_STYLE_LONG:
				case DATE_STYLE_FULL:
					return formatDateTime(res, t, "T");
					break;
				case DATE_STYLE_SHORT:
				case DATE_STYLE_MEDIUM:
				default:
					return formatDateTime(res, t, "t");
				}
				break;
			
			case FORMAT_DATETIME:
			default:
				switch(p.secondaryFormat)
				{
				case DATE_STYLE_CUSTOM:
					return formatDateTime(res, t, p.formatString);
				case DATE_STYLE_LONG:
				case DATE_STYLE_FULL:
					return formatDateTime_(t);
					//return formatDateTime(res, t, "G");
				case DATE_STYLE_SHORT:
				case DATE_STYLE_MEDIUM:
				default:
					return formatDateTime_(t);
					//return formatDateTime(res, t, "g");
				}
				break;
			}
		}
	}
}

package class PluralMessage : IMessage
{
	Message[] pluralForms;
	char[] pluralVariable;
	bool plural() {return true;}
	
	char[] exec(IObject ctxt)
	{
		auto v = ctxt.getVar(pluralVariable);
		
		assert(false, "PluralMessage not implemented yet");
		
		return null;
	}
}

class MessageParserException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}

const ubyte Excl = 1;
const ubyte LeftBrace = 2;
const ubyte RightBrace = 3;
const ubyte Times = 4;
const ubyte Plus = 5;
const ubyte Minus = 6;
const ubyte Divide = 7;
const ubyte LT = 8;
const ubyte Equals = 9;
const ubyte GT = 10;

const ubyte Quote = 100;
const ubyte SingleQuote = 101;
const ubyte Numeric = 243;
const ubyte DollarSign = 244;
const ubyte Identifier = 255;


const ubyte lookupT[256] = 
    [
      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 0
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
         0,  Excl,  0,  0,  0,  0,  0,  0,  LeftBrace,  RightBrace,  0,  0,  0,  0,  0,  0,  // 2
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  Equals,  0,  0,  // 3
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 4
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 5
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 6
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 7
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 8
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 9
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // A
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // B
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // C
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // D
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // E
         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   // F
    ];
/+
public void parseExpression(char[] msg, inout Expression expression, FunctionBindingContext ctxt)
{
	scope itr = new StringCharIterator!(char)(msg);
	
	void parseExpr(inout Expression expr)
	{
		void parseFunction()
		{
			void parseFuncParams()
			{				
				bool parseParam()
				{
					itr.eatSpace;
					if(itr[0] == ')') return false;
					
					Expression p;
					parseExpr(p);
					expr.func.params ~= p;
					switch(itr[0])
					{
					case ',':
						++itr;
						return true;
					case ')':
						++itr;
						return false;
					default:
						debug new MessageParserException("expected ',' or ')' in function parameters");
						return false;
					}
				}
				
				expr.func.params.length = 0;
				while(parseParam) {};			
			}
			
			uint i = itr.location;
			if(!itr.forwardLocate('(')) throw new MessageParserException("Expected ( after function name in \'" ~ msg ~ "\'");
			uint j = itr.location;
			char[] name = itr.randomAccessSlice(i, j);
			auto fn = ctxt.getFunction(name);
			if(!fn) {
				fn = new LateBindingFunction(name);
				//new MessageParserException("Unable to find definition of function " ~ name); 
			}
			expr.func.func = fn;
			++itr;
			parseFuncParams();
			expr.type = ExpressionT.FuncCall;
		}
		
		void parseBinaryExpr()
		{
			++itr;
			if(itr[0] != '=') return;
			++itr;
			itr.eatSpace;
			Expression expr1 = expr;
			Expression expr2;
			parseExpr(expr2);
			expr.type = ExpressionT.Binary;
			expr.binaryExpr.type = OperatorT.Eq;
			expr.binaryExpr.expr[0] = expr1;
			expr.binaryExpr.expr[1] = expr2;
		}
		
		//while(itr.good) {
			auto x = lookupT[itr[0]];
			switch(itr[0])
			{
			case '$':
				++itr;
				char[] var;
				while(itr.good) {
					if(itr[0] == ',' || itr[0] == ')' || itr[' '])
						break;
					var ~= itr[0];
					++itr;
				}
				expr.var = VarPath(var);
				expr.type = ExpressionT.Var;
				return;
			case '\"', '\'':
				char quote = itr[0];
				char[] str;
				++itr;
				while(itr.good) {
					if(itr[0] == '\\') {
						str ~= itr[1];
						itr += 2;
					}
					else if(itr[0] == quote) {
						++itr;
						break;
					}
					else {
						str ~= itr[0];
						++itr;
					}
				}
				expr.type = ExpressionT.Value;
				expr.val.set(str);
				break;
		/*	case '=':
				parseBinaryExpr();
				break;*/
			default:
				parseFunction();
				return;
			}
			itr.eatSpace;
		//}
	}
	
	parseExpr(expression);
}+/

Message parseMessage(char[] msg, FunctionBindingContext ctxt)
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
		j = Text.locate(exprTxt, ';');
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
/+		case 'h':
			if(itr[0 .. 10] == "htmlencode") {
				itr += 10;
				p.elementFormat = ENCODE_ENTITIES;
			}
			else return unexpectedFormat();+/
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
				res ~= '_';
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

/*void parseTextExpression(char[] text, inout Expression expr, FunctionBindingContext ctxt)
{
	auto msg = parseMessage(text, ctxt);
	if(!msg.msg.length && msg.params.length == 1) {
		expr = msg.params[0].expr;
	}
	else {
		expr.type = ExpressionT.TextExpr;
		expr.textExpr = msg;
	}
}*/

version(SenderoUnittest)
{
	import tango.io.Stdout;


unittest
{
	auto funcCtxt = new FunctionBindingContext;
	auto m = parseMessage("Hello _{$word} world, the only _{$num|spellout}!", funcCtxt);
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
	//assert(res == "Hello beautiful world, the only one!", res);
	Stdout(res).newline;
/+	
	Expression expr;
	parseExpression("\"hello\"", expr, FunctionBindingContext.global);
	assert(expr.type == ExpressionT.Value);
	auto var = expr.exec(ExecutionContext.global);
	assert(var.type == VarT.String);
	assert(var.string_ == "hello");
	
	parseExpression("'hello'", expr, FunctionBindingContext.global);
	assert(expr.type == ExpressionT.Value);
	var = expr.exec(ExecutionContext.global);
	assert(var.type == VarT.String);
	assert(var.string_ == "hello");
	
	parseExpression("now()", expr, FunctionBindingContext.global);
	assert(expr.type == ExpressionT.FuncCall);
	var = expr.exec(ExecutionContext.global);
	assert(var.type == VarT.DateTime);+/	
}
}