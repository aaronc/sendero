/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */

module sendero.json.JsonParser;

public import sendero.util.ICharIterator;
import sendero.util.StringCharIterator;

enum JSONTokenType { Name, String, Number, BeginObject, EndObject, BeginArray, EndArray, True, False, Null, Empty };

class JSONParser(Ch, Int = uint)
{
	this(Ch[] text)
	{
		this.itr = new StringCharIterator!(Ch)(text);
	}
	
	this(ICharIterator!(Ch) itr)
	{
		this.itr = itr;
	}
	
	private ICharIterator!(Ch) itr;
	
	private Int curLoc;
	private Int curLen;
	private JSONTokenType curType = JSONTokenType.Empty;
	private ushort arrayDepth = 0;
	private ushort curDepth = 0;
	private bool retain = false;	
	
	private void eatWhitespace()
	{
		while(itr.good && Lookup.whitespace[itr[0]]) ++itr;
	}
	
	private bool parseMemberName()
	{
		if(itr[0] == '}') return endObject;
		
		if(itr[0] == ',') ++itr;
		
		eatWhitespace;

		if(itr[0] != '"') return false;
		++itr;
		
		curType = JSONTokenType.Name;
		curLoc = itr.location;
		
		while(itr.good) {
			if(itr[0] == '"') {
				if(itr[-1] != '\\')
					break;
			}
			++itr;
		}
		if(!itr.good) return false;
		curLen = itr.location - curLoc;
		++itr;
			
		return true;
	}
	
	private bool doString()
	{
		if(itr[0] != '"') return false;
		++itr;
		
		curType = JSONTokenType.String;
		curLoc = itr.location;
		
		while(itr.good) {
			if(itr[0] == '"') {
				if(itr[-1] != '\\')
					break;
			}
			++itr;
		}
		if(!itr.good) return false;
		curLen = itr.location - curLoc;
		++itr;
		
		return true;
	}
	
	private bool parseValue()
	{			
		switch(itr[0])
		{
		case '"':
			return doString;
			break;
		case '{':
			return beginObject;
			break;
		case '[':
			return beginArray;
			break;
		case 't':
			return doTrue;
			break;
		case 'f':
			return doFalse;
			break;
		case 'n':
			return doNull;
			break;
		default:
			return parseNumber;
			break;
		}
	}
	
	private bool parseMemberValue()
	{
		if(itr[0] != ':') return false;
		++itr;
		eatWhitespace;
		
		return parseValue;
	}
	
	private bool parseNumber()
	{
		curLoc = itr.location;
		curType = JSONTokenType.Number;
		
		while(itr.good && Lookup.number[itr[0]]) ++itr;
		if(!itr.good) return false;
		
		curLen = itr.location - curLoc;
		++itr;
		
		return true;
	}
	
	private bool doTrue()
	{
		if(itr[0..4] != "true")
			return false;
		curLoc = itr.location;
		itr += 4;
		curLen = 4;
		curType = JSONTokenType.True;
		return true;
	}
	
	private bool doFalse()
	{
		if(itr[0..5] != "false")
			return false;
		curLoc = itr.location;
		itr += 5;
		curLen = 5;
		curType = JSONTokenType.False;
		return true;
	}
	
	private bool doNull()
	{
		if(itr[0..4] != "null")
			return false;
		curLoc = itr.location;
		itr += 4;
		curLen = 4;
		curType = JSONTokenType.Null;
		return true;
	}
	
	private bool parseObject()
	{
		if(itr[0] != '{') return false;
		return beginObject;
	}
	
	private bool beginObject()
	{
		++curDepth;
		curType = JSONTokenType.BeginObject;
		curLoc = itr.location;
		curLen = 0;
		++itr;
		return true;
	}
	
	private bool endObject()
	{
		--curDepth;
		curType = JSONTokenType.EndObject;
		curLoc = itr.location;
		curLen = 0;
		++itr;
		return true;
	}
	
	private bool beginArray()
	{
		++arrayDepth;
		curType = JSONTokenType.BeginArray;
		curLoc = itr.location;
		curLen = 0;
		++itr;
		return true;
	}
	
	private bool endArray()
	{
		--arrayDepth;
		curType = JSONTokenType.EndArray;
		curLoc = itr.location;
		curLen = 0;
		++itr;
		return true;
	}
	
	private bool parseArrayValue()
	{
		if(itr[0] == ']') return endArray;
		
		if(itr[0] == ',') ++itr;
		eatWhitespace;
		return parseValue;
	}
	
	bool next()
	{
		if(!itr.good) {
			return false;
		}
		
		if(retain) {
			retain = false;
			return true;
		}
		
		eatWhitespace;
		
		if(arrayDepth > 0) {
			return parseArrayValue;
		}
		
		switch(curType)
		{
		case JSONTokenType.Empty:
			return parseObject;
			break;
		case JSONTokenType.Name:
			return parseMemberValue;
			break;
		case JSONTokenType.String:
		case JSONTokenType.Number:
		case JSONTokenType.EndObject:
		case JSONTokenType.BeginObject:
		case JSONTokenType.EndArray:
		case JSONTokenType.True:
		case JSONTokenType.False:
		case JSONTokenType.Null:
		default:		
			return parseMemberName;
			break;
		}
		
	}
	
	JSONTokenType type()
	{
		return curType;
	}
	
	Ch[] value()
	{
		return itr.randomAccessSlice(loc, loc + len);
	}
	
	Int loc()
	{
		return curLoc;
	}
	
	Int len()
	{
		return curLen;
	}
	
	ushort depth()
	{
		return curDepth;
	}
	
	bool reset()
	{
		return itr.seek(0);
	}
	
	void retainCurrent()
	{
		retain = true;
	}
}

private class Lookup
{
	const static ubyte[256] whitespace =
		[
	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  0,  0,  // 0
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
	         1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 2
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 3
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 4
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 5
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 6
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 7
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 8
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 9
	         1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // A
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // B
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // C
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // D
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // E
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   // F
	    ];
	
	const static ubyte[256] number =
		[
	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 0
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  1,  1,  0,  // 2
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  // 3
	         0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 4
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 5
	         0,  0,  0,  0,  0,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 6
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
}

version(Unittest)
{
	class TestCase
	{
		const static char[] one = 
		"{"
			"\"glossary\": {"
		        "\"title\": \"example glossary\","
				"\"GlossDiv\": {"
				" 	\"title\": \"S\","
				"	\"GlossList\": {"
				"       \"GlossEntry\": {"
				"           \"ID\": \"SGML\","
				"			\"SortAs\": \"SGML\","
				"			\"GlossTerm\": \"Standard Generalized Markup Language\","
				"			\"Acronym\": \"SGML\","
				"			\"Abbrev\": \"ISO 8879:1986\","
				"			\"GlossDef\": {"
		        "                \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\","
				"				\"GlossSeeAlso\": [\"GML\", \"XML\"]"
		        "            },"
				"			\"GlossSee\": \"markup\","
				"			\"ANumber\": 12345.6e7"
				"			\"True\": true"
				"			\"False\": false"
				"			\"Null\": null"
		        "        }"
				"    }"
		        "}"
		    "}"
		"}";
	}
}

unittest
{
	
	
	auto text = new StringCharIterator!(char)(TestCase.one); 
	auto p = new JSONParser!(char)(text);
	assert(p);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "glossary", p.value);
	assert(p.next);
	assert(p.value == "", p.value);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "title", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "example glossary", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossDiv", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "title", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "S", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossList", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossEntry", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "ID", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "SGML", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "SortAs", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "SGML", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossTerm", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "Standard Generalized Markup Language", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "Acronym", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "SGML", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "Abbrev", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "ISO 8879:1986", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossDef", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "para", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "A meta-markup language, used to create markup languages such as DocBook.", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossSeeAlso", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.BeginArray);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "GML", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "XML", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.EndArray);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "GlossSee", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.String);
	assert(p.value == "markup", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "ANumber", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Number);
	assert(p.value == "12345.6e7", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "True", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.True);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "False", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.False);
	assert(p.next);
	assert(p.type == JSONTokenType.Name);
	assert(p.value == "Null", p.value);
	assert(p.next);
	assert(p.type == JSONTokenType.Null);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(p.next);
	assert(p.type == JSONTokenType.EndObject);
	assert(!p.next);
	assert(p.depth == 0);
}