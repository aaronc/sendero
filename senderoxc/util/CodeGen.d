module senderoxc.util.CodeGen;

char[] DQuoteString(char[] str)
{
	auto len = str.length;
	char[] res = new char[len + 7];
	res.length = 0;
	res ~= '"';
	foreach(ch; str)
	{
		if(ch == '"') res ~= "\\\"";
		else res ~= ch;
	}
	res ~= '"';
	return res;
}
alias DQuoteString DQuote;

char[] makeList(char[][] list, char[] sep = ", ")
{
	char[] res;
	auto n = list.length;
	for(uint i = 0; i < n; ++i)
	{
		res ~= list[i];
		if(i < n - 1) res ~= sep;
	}
	return res;
}

char[] makeQuotedList(char[][] list, char[] sep = ", ")
{
	char[] res;
	auto n = list.length;
	for(uint i = 0; i < n; ++i)
	{
		res ~= DQuoteString(list[i]);
		if(i < n - 1) res ~= sep;
	}
	return res;
}