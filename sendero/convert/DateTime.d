module sendero.convert.DateTime;

public import tango.time.Time;
import tango.util.Convert;

/* TODO
 * 
 * MMM Sept
 * MMMM September
 * eee/EEE Tues
 * eeee/EEEE Tuesday
 * 
 */
class ExactDateTimeParser
{	
	this(char[] format)
	{
		format_ = format;
		compile();
	}
	
	private char[] format_;
	char[] format() { return format_; }

	private void compile()
	{
		 int parseQuote(char[] format, int pos, out char[] result)
         {
                 int start = pos;
                 char chQuote = format[pos++];
                 bool found;
                 while (pos < format.length)
                       {
                       char c = format[pos++];
                       if (c is chQuote)
                          {
                          found = true;
                          break;
                          }
                       else
                          if (c is '\\')
                             { // escaped
                             if (pos < format.length)
                                 result ~= format[pos++];
                             }
                          else
                             result ~= c;
                       }
                 return pos - start;
         }
		 
		 int parseRepeat(char[] format, int pos, char c)
         {
                 int n = pos + 1;
                 while (n < format.length && format[n] is c)
                         n++;
                 return n - pos;
         }
		
		uint index = 0;
		uint len = 0;
    	while (index < format_.length)
    	{
    		char c = format_[index];

    		switch (c)
    		{
            case 'd':  // day
                len = parseRepeat(format, index, c);
                if (len <= 2)
                	parsers ~= ddParser();
                else
                	assert(false);
                	//parsers ~= ddParser();
                break;

           case 'M':  // month
                len = parseRepeat(format, index, c);
                if (len <= 2)
                	parsers ~= MParser();
                else
                	assert(false);
    //            justTime = false;
                break;
           case 'y':  // year
                len = parseRepeat(format, index, c);
                if (len <= 2)
                	assert(false);
                else
                	parsers ~= yyyyParser();
                break;
   /+        case 'h':  // hour (12-hour clock)
                len = parseRepeat(format, index, c);
                break;
           case 'H':  // hour (24-hour clock)
                len = parseRepeat(format, index, c);
                break;
           case 'm':  // minute
                len = parseRepeat(format, index, c);
                break;
           case 's':  // second
                len = parseRepeat(format, index, c);
                break;
           case 't':  // AM/PM
                len = parseRepeat(format, index, c);
                if (len is 1)
                   {
                   if (time.hours < 12)
                      {
                      if (dtf.amDesignator.length != 0)
                          result ~= dtf.amDesignator[0];
                      }
                   else
                      {
                      if (dtf.pmDesignator.length != 0)
                          result ~= dtf.pmDesignator[0];
                      }
                   }
                else
                   result ~= (time.hours < 12) ? dtf.amDesignator : dtf.pmDesignator;
                break;
           case 'z':  // timezone offset
                len = parseRepeat(format, index, c);
version (Full)
{
                TimeSpan offset = (justTime && dateTime.ticks < TICKS_PER_DAY)
                                   ? TimeZone.current.getUtcOffset(WallClock.now)
                                   : TimeZone.current.getUtcOffset(dateTime);
                int hours = offset.hours;
                int minutes = offset.minutes;
                result ~= (offset.backward) ? '-' : '+';
}
else
{
                auto minutes = cast(int) (WallClock.zone.minutes);
                if (minutes < 0)
                    minutes = -minutes, result ~= '-';
                else
                   result ~= '+';
                int hours = minutes / 60;
                minutes %= 60;
}
                if (len is 1)
                    result ~= formatInt (tmp, hours, 1);
                else
                   if (len is 2)
                       result ~= formatInt (tmp, hours, 2);
                   else
                      {
                      result ~= formatInt (tmp, hours, 2);
                      result ~= ':';
                      result ~= formatInt (tmp, minutes, 2);
                      }
                break;
           case ':':  // time separator
                len = 1;
                result ~= dtf.timeSeparator;
                break;
           case '/':  // date separator
                len = 1;
                result ~= dtf.dateSeparator;
                break;
           case '\"':  // string literal
           case '\'':  // char literal
                char[] quote;
                len = parseQuote(format, index, quote);
                result ~= quote;
                break;+/
           default:
               len = 1;
           	   parsers ~= Expect(c);
            //   result ~= c;
               break;
           }
    index += len;
    }
	}
	
	
	Parser[] parsers;
	
	
	bool convert(char[] str, inout DateTime dt)
	{
		auto ptr = str.ptr;
		auto end = ptr + str.length + 1;
		foreach(p; parsers)
		{
			if(!p(ptr, end, dt)) return false;
		}
		return true;
	}
}

/+class dParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		if(ptr + 2 > end) return false;
		
	}
}
+/
alias bool delegate(inout char* ptr, char* end, inout DateTime dt) Parser;

template ParserSingleton(char[] cls)
{
	const char[] ParserSingleton = "static Parser opCall()"
	"{"
		"if(!inst) inst = new " ~ cls ~ ";"
		"return &inst.parse;"
	"}"
	"private static " ~ cls ~ " inst;";
}

class ddParser
{
	mixin(ParserSingleton!("ddParser"));
	
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		if(end - ptr < 2) return false;
		auto res = to!(uint)(ptr[0 .. 2]);
		if(res > 31) return false;
		dt.date.day = res;
		ptr += 2;
		return true;
		
	}
}

class MParser /* M or MM */
{
	mixin(ParserSingleton!("MParser"));
	
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		if(end - ptr < 2) return false;
		auto res = to!(uint)(ptr[0 .. 2]);
		if(res > 12) return false;
		dt.date.month = res;
		ptr += 2;
		return true;
	}
}
/+

class yyParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}+/

class yyyyParser /* yyyy or y */
{
	mixin(ParserSingleton!("yyyyParser"));
	
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		if(end - ptr < 4) return false;
		dt.date.year = to!(uint)(ptr[0 .. 4]);
		ptr += 4;
		return true;
	}
}

class Expect
{
	static Parser opCall(char[] expect)
	{
		return &(new Expect(expect)).parse;
	}
	
	static Parser opCall(char expect)
	{
		return &(new Expect([expect])).parse;
	}
	
	this(char[] expect)
	{
		this.expect = expect;
	}
	
	private char[] expect;
	
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		if(end - ptr < expect.length) return false;
		if(ptr[0 .. expect.length] != expect) return false;
		ptr += expect.length;
		return true;
	}
}
/+
class hParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class hhParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class HParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class HHParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class mParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class mmParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class sParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}

class ssParse
{
	bool parse(inout char* ptr, char* end, inout DateTime dt)
	{
		
	}
}
+/
version(Unittest)
{
import tango.io.Stdout;
	
unittest
{
	DateTime dt;
	auto parser = new ExactDateTimeParser("yyyy-MM-dd");
/+	parser.parsers ~= &(new yyyyParser).parse;
	parser.parsers ~= &(new Expect("-")).parse;
	parser.parsers ~= &(new MParser).parse;
	parser.parsers ~= &(new Expect("-")).parse;
	parser.parsers ~= &(new ddParser).parse;+/
	assert(parser.convert("1998-01-02", dt));
	assert(dt.date.year == 1998);
	assert(dt.date.month == 1);
	assert(dt.date.day == 2);
}
}