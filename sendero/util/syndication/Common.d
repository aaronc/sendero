module sendero.util.syndication.Common;

static import tango.text.xml.Document;
alias tango.text.xml.Document.Document!(char) XmlDocument;
alias tango.text.xml.Document.XmlNodeType XmlNodeType;

template AbstractFeed()
{
	char[] src;
	char[] url;
	
	this(char[] url)
	{
		this.url = url;
	}
	
	bool get()
	{
		try
		{
			auto page = new HttpGet(url);
			auto res = cast(char[])page.read;
			parse_(res);
			return true;
		}
		catch(Exception ex)
		{
			return false;
		}
	}
	
	abstract private void parse_(char[] src);
}