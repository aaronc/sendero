module sendero.locale.Data;

struct DateTimeFormat
{
	char[] date_full;
	char[] date_long;
	char[] date_medium;
	char[] date_short;
	char[] time_full;
	char[] time_long;
	char[] time_medium;
	char[] time_short;
	enum DTOrder {DateTime, TimeDate};
	DTOrder dt_order;
	
	char[][] monthes_abbrev;
	char[][] monthes_wide;
	char[][] monthes_narrow;
	
	char[][] days_abbrev;
	char[][] days_wide;
	char[][] days_narrow;
	
	//char[][] quarters_abbrev;
	//char[][] quarters_wide;
	
	char[] am;
	char[] pm;
	
	
}

enum NF {
	GroupingSep,
	DecimalSep,
	Minus,
	Digit,
	Zero,
	Currency
}

struct NumberFormat
{
	NF[] decimal;
	NF[] scientific;
	NF[] percent;
	NF[] currency;
}