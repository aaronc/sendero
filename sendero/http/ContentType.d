module sendero.http.ContentType;

struct ContentType
{
	const char[] TextHtml = "text/html; charset=utf-8";
	const char[] AppXml = "application/xml";
	const char[] TextJSON = "text/json";
	const char[] AppJS = "application/javascript";
}
alias ContentType Mime;