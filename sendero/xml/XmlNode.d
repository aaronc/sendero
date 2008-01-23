module sendero.xml.XmlNode;

public import sendero.xml.XmlNodeType;
import sendero.xml.XmlParser;

class XmlNode
{
public:
	XmlNodeType type;
	char[] prefix;
	char[] localName;
	uint uriID = 0;
	
	final char[] name()
    {
    	if(prefix.length)
    		return prefix ~ ":" ~ localName;
    	return localName;
    }
	
	char[] rawValue;

	final char[] value()
	{
		if(type == XmlNodeType.Data || type == XmlNodeType.Attribute)
    		return decodeBuiltinEntities!(char)(rawValue);
    	return rawValue;
	}
	
	final void value(char[] val)
	{
		rawValue = encodeBuiltinEntities!(char)(val);
	}
	
	final INodeSetViewer children() {return new ChildAxisViewer(this);}
	final INodeSetViewer attributes() {return new AttributeAxisViewer(this);}
	final XmlNode parent() { return parent_; }
	final XmlNode firstChild() { return firstChild_; }
	final XmlNode lastChild() { return lastChild_; }
	final XmlNode prevSibling() { return prevSibling_; }
	final XmlNode nextSibling() { return nextSibling_; }
	
	final void append(XmlNode node)
	{
/+		if(node.parent_) throw new Exception("Trying to append node that already has a parent"
		                                     "- this operation will break that node's tree. "
		                                     "Please append a new node to the tree instead.");+/
		node.parent_ = this;
		if(!lastChild_) {
			firstChild_ = node;
			lastChild_ = node;
		}
		else {
			lastChild_.nextSibling_ = node;
			node.prevSibling_ = lastChild_;
			lastChild_ = node;
		}
	}
	
	final void prepend(XmlNode node)
	{
		node.parent_ = this;
		if(!firstChild_) {
			firstChild_ = node;
			lastChild_ = node;
		}
		else {
			firstChild_.prevSibling_ = node;
			node.nextSibling_ = firstChild_;
			firstChild_ = node;
		}
	}
	
	final void insertAfter(XmlNode node)
	{
		node.parent_ = parent_;
		if(nextSibling_) {
			nextSibling_.prevSibling_ = node;
			node.nextSibling_ = nextSibling_;
			node.prevSibling_ = this;
			nextSibling_ = node;
		}
		else {
			node.prevSibling_ = this;
			node.nextSibling_ = null;
			nextSibling_ = node;
		}
	}
	
	final void insertBefore(XmlNode node)
	{
		node.parent_ = parent_;
		if(prevSibling_) {
			prevSibling_.nextSibling_ = node;
			node.prevSibling_ = prevSibling_;
			node.nextSibling_ = this;
			prevSibling_ = node;
		}
		else {
			node.nextSibling_ = this;
			node.prevSibling_ = null;
			prevSibling_ = node;
		}
	}
	
	final void remove()
	{
		if(!parent_) return;
		
		if(prevSibling_ && nextSibling_) {
			prevSibling_.nextSibling_ = nextSibling_;
			nextSibling_.prevSibling_ = prevSibling_;
			prevSibling_ = null;
			nextSibling_ = null;
			parent_ = null;
		}
		else if(nextSibling_)
		{
			debug assert(parent_.firstChild_ == this);
			parent_.firstChild_ = nextSibling_;
			nextSibling_.prevSibling_ = null;
			nextSibling_ = null;
			parent_ = null;
			
		}
		else if(type != XmlNodeType.Attribute)
		{
			if(prevSibling_)
			{
				debug assert(parent_.lastChild_ == this);
				parent_.lastChild_ = prevSibling_;
				prevSibling_.nextSibling_ = null;
				prevSibling_ = null;
				parent_ = null;
			}
			else
			{
				debug assert(parent_.firstChild_ == this);
				debug assert(parent_.lastChild_ == this);
				parent_.firstChild_ = null;
				parent_.lastChild_ = null;
				parent_ = null;
			}
		}
		else
		{
			if(prevSibling_)
			{
				debug assert(parent_.lastAttr_ == this);
				parent_.lastAttr_ = prevSibling_;
				prevSibling_.nextSibling_ = null;
				prevSibling_ = null;
				parent_ = null;
			}
			else
			{
				debug assert(parent_.firstAttr_ == this);
				debug assert(parent_.lastAttr_ == this);
				parent_.firstAttr_ = null;
				parent_.lastAttr_ = null;
				parent_ = null;
			}
		}
	}
	
	final void appendAttribute(char[] prefix, char[] localName, char[] value, uint uriID = 0)
	{
		auto attr = new XmlNode;
		attr.prefix = prefix;
		attr.localName = localName;
		attr.rawValue = value;
		attr.uriID = uriID;
		attr.parent_ = this;
		attr.type = XmlNodeType.Attribute;
		if(!firstAttr_) {
			firstAttr_ = attr;
			lastAttr_ = attr;
		}
		else {
			lastAttr_.nextSibling_ = attr;
			attr.prevSibling_ = lastAttr_;
			lastAttr_ = attr;
		}
	}
	
	bool hasChildren() { return firstChild_ !is null; }
	
private:
	XmlNode parent_ = null;
	XmlNode prevSibling_ = null;
	XmlNode nextSibling_ = null;
	XmlNode firstChild_ = null;
	XmlNode lastChild_ = null;
	
	XmlNode firstAttr_ = null;
	XmlNode lastAttr_ = null;
	uint[char[]] namespaceURIs;
}


interface INodeSetViewer
{
	int opApply(int delegate(inout XmlNode) dg);
}

template NodeSetViewerPrimitive()
{
	private XmlNode node;
	this(XmlNode node)
	{
		this.node = node;
	}
}

class SelfAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		res = dg(node);
		return res;
	}
}

class ParentAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		if(!node.parent_) return res;
		res = dg(node.parent_);
		return res;
	}
}

class AncestorAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		auto cur = node.parent_;
		while(cur) {
			if((res = dg(node.parent_)) != 0) break;
			cur = cur.parent_;
		}
		
		return res;
	}
}

class AncestorOrSelfAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		
		if((res = dg(node)) != 0) return res;
		
		auto cur = node.parent_;
		while(cur) {
			if((res = dg(node.parent_)) != 0) break;
			cur = cur.parent_;
		}
		
		return res;
	}
}


class ChildAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		auto cur = node.firstChild_;
		if(!cur) return res;
		if((res = dg(cur)) != 0) return res;
		cur = cur.nextSibling_;
		while(cur) {
			if((res = dg(cur)) != 0) break;
			cur = cur.nextSibling_;
		}
		return res;
	}
}

class AttributeAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		auto cur = node.firstAttr_;
		if(!cur) return res;
		if((res = dg(cur)) != 0) return res;
		cur = cur.nextSibling_;
		while(cur) {
			if((res = dg(cur)) != 0) break;
			cur = cur.nextSibling_;
		}
		return res;
	}
}

template DoDescendantAxis()
{
	const char[] DoDescendantAxis = "void doAxis(XmlNode n)"
	"{"
		"auto cur = n.firstChild_;"
		"if(!cur) return;"
		"if((res = dg(cur)) != 0) return;"
		"doAxis(cur);"
		"cur = cur.nextSibling_;"
		"while(cur) {"
			"if((res = dg(cur)) != 0) return;"
			"doAxis(cur);"
			"cur = cur.nextSibling_;"
		"}"
	"}";
}

template DoReverseDescendantAxis()
{
	const char[] DoReverseDescendantAxis = "void doAxis(XmlNode n)"
	"{"
		"auto cur = n.lastChild_;"
		"if(!cur) return;"
		"if((res = dg(cur)) != 0) return;"
		"doAxis(cur);"
		"cur = cur.prevSibling_;"
		"while(cur) {"
			"if((res = dg(cur)) != 0) return;"
			"doAxis(cur);"
			"cur = cur.prevSibling_;"
		"}"
	"}";
}

class DescendantAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		
		mixin(DoDescendantAxis!());
		
		doAxis(node);
		return res;
	}
}

class DescendantOrSelfAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res = 0;
		
		mixin(DoDescendantAxis!());
		
		if((res = dg(node)) != 0) return res;
		
		doAxis(node);
		return res;
	}
}

class FollowingAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res;
		
		void doFollowing(XmlNode x)
		{
			mixin(DoDescendantAxis!());
			
			auto cur = x.nextSibling_;
			while(cur) {
				if((res = dg(cur)) != 0) break;
				doAxis(cur);
				cur = cur.nextSibling_;
			}
			
			if(x.parent_) {
				doFollowing(x.parent_);
			}
		}
		
		doFollowing(node);
		
		return res;
	}
}

class FollowingSiblingAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res;
		auto cur = node.nextSibling_;
		while(cur) {
			if((res = dg(cur)) != 0) break;
			cur = cur.nextSibling_;
		}
		return res;
	}
}

class PrecedingAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res;
		
		void doPreceding(XmlNode x)
		{
			mixin(DoReverseDescendantAxis!());
			
			auto cur = x.prevSibling_;
			while(cur) {
				if((res = dg(cur)) != 0) break;
				doAxis(cur);
				cur = cur.prevSibling_;
			}
			
			if(x.parent_) {
				doPreceding(x.parent_);
			}
		}
		
		doPreceding(node);
		
		return res;
	}
}

class PrecedingSiblingAxisViewer : INodeSetViewer
{
	mixin NodeSetViewerPrimitive!();
	
	int opApply(int delegate(inout XmlNode) dg)
	{
		int res;
		auto cur = node.prevSibling_;
		while(cur) {
			if((res = dg(cur)) != 0) break;
			cur = cur.prevSibling_;
		}
		return res;
	}
}


XmlNode XmlElement(char[] prefix, char[] localName, XmlNode contents = null)
{
	auto node = new XmlNode;
	node.type = XmlNodeType.Element;
	node.prefix = prefix;
	node.localName = localName;
	return node;
}

XmlNode XmlData(char[] data)
{
	auto node = new XmlNode;
	node.type = XmlNodeType.Data;
	node.rawValue = data;
	return node;
}

XmlNode XmlPI(char[] pi)
{
	auto node = new XmlNode;
	node.type = XmlNodeType.PI;
	node.rawValue = pi;
	return node;
}

XmlNode XmlDoctype(char[] doctype)
{
	auto node = new XmlNode;
	node.type = XmlNodeType.Doctype;
	node.rawValue = doctype;
	return node;
}

XmlNode XmlComment(char[] comment)
{
	auto node = new XmlNode;
	node.type = XmlNodeType.Comment;
	node.rawValue = comment;
	return node;
}

const char[] xmlURI = "http://www.w3.org/XML/1998/namespace";
const char[] xmlnsURI = "http://www.w3.org/2000/xmlns/";

XmlNode parseXmlTree(char[] xml)
{
	auto itr = new XmlParser!(char)(xml);
	itr.reset(xml);
	auto doc = new XmlNode;
	doc.type = XmlNodeType.Document;
	auto cur = doc;
	
	uint[char[]] namespaceURIs;
	namespaceURIs[xmlURI] = 1;
	namespaceURIs[xmlnsURI] = 2;
	uint defNamespace;
	uint[char[]] inscopeNSs;
	inscopeNSs["xml"] = 1;
	inscopeNSs["xmlns"] = 2;
	
	while(itr.next) {
		
		switch(itr.type) 
		{
		case XmlTokenType.StartElement:
			auto node = new XmlNode;
			node.type = XmlNodeType.Element;
			node.prefix = itr.prefix;
			
			if(itr.prefix) {
				auto pURI = itr.prefix in inscopeNSs;
				if(pURI) node.uriID = *pURI;
				else {
					debug(XmlNamespaces) assert(false, "Unresolved namespace prefix:" ~ itr.prefix);
					node.uriID = 0;
				}
			}
			else node.uriID = defNamespace;
			
			node.localName = itr.localName;
			node.parent_ = cur;
			if(!cur.lastChild_) {
				cur.firstChild_ = node;
				cur.lastChild_ = node;
			}
			else {
				cur.lastChild_.nextSibling_ = node;
				node.prevSibling_ = cur.lastChild_;
				cur.lastChild_ = node;
			}
			cur = node;
			break;
		case XmlTokenType.Data:
			auto node = new XmlNode;
			node.type = XmlNodeType.Data;
			node.rawValue = itr.rawValue;
			cur.append(node);
			break;
		case XmlTokenType.Attribute:
			if(itr.prefix) {
				if(itr.prefix == "xmlns") {
					uint uri;
					if(itr.rawValue != "") {
						auto pURI = (itr.rawValue in namespaceURIs);
						if(!pURI) {
							uri = namespaceURIs.length + 1;
							namespaceURIs[itr.rawValue] = uri;
						}
						else uri = *pURI;
					}
					else uri = 0;
					
					if(!itr.localName) defNamespace = uri;
					else inscopeNSs[itr.localName] = uri;
				}
				auto pURI = itr.prefix in inscopeNSs;
				if(pURI) cur.appendAttribute(itr.prefix, itr.localName, itr.rawValue, *pURI);
				else {
					debug(XmlNamespaces) assert(false, "Unresolved namespace prefix:" ~ itr.prefix);
					cur.appendAttribute(itr.prefix, itr.localName, itr.rawValue, 0);
				}
			}
			else cur.appendAttribute(itr.prefix, itr.localName, itr.rawValue, defNamespace);
			break;
		case XmlTokenType.EndElement:
			if(!cur.hasChildren) {
				auto dummy = new XmlNode;
				dummy.type = XmlNodeType.Data;
				cur.append(dummy);
			}
			assert(cur.parent_);
			cur = cur.parent_;			
			break;
		case XmlTokenType.EndEmptyElement:
			assert(cur.parent_);
			cur = cur.parent_;
			break;
		case XmlTokenType.Comment:
			auto node = new XmlNode;
			node.type = XmlNodeType.Comment;
			node.rawValue = itr.rawValue;
			cur.append(node);
			break;
		case XmlTokenType.PI:
			auto node = new XmlNode;
			node.type = XmlNodeType.PI;
			node.rawValue = itr.rawValue;
			cur.append(node);
			break;
		case XmlTokenType.CData:
			auto node = new XmlNode;
			node.type = XmlNodeType.CData;
			node.rawValue = itr.rawValue;
			cur.append(node);
			break;
		case XmlTokenType.Doctype:
			auto node = new XmlNode;
			node.type = XmlNodeType.Doctype;
			node.rawValue = itr.rawValue;
			cur.append(node);
			break;
		default:
			break;
		}
	}
	
	doc.namespaceURIs = namespaceURIs;
	return doc;
}

char[] print(XmlNode root)
{
	char[] res;
	void printNode(XmlNode node)
	{
		if(node.type == XmlNodeType.Document)
		{
			foreach(n; node.children)
			{
				printNode(n);
			}
		}
		else if(node.type == XmlNodeType.Element)
		{
			res ~= "<" ~ node.name;
			foreach(attr; node.attributes)
			{
				res ~= " " ~ print(attr);
			}
			if(node.hasChildren)
			{
				res ~= ">";
				foreach(n; node.children)
				{
					printNode(n);
				}
				res ~= "</" ~ node.name ~ ">";
			}
			else res ~= " />";	
		}
		else if(node.type == XmlNodeType.Data)
		{
			res ~= node.rawValue;
		}
		else if(node.type == XmlNodeType.Attribute)
		{
			res ~= node.name ~ "=\"" ~ node.rawValue ~ "\"";
		}
		else if(node.type == XmlNodeType.Comment)
		{
			res ~= "<!--" ~ node.rawValue ~ "-->";
		}
		else if(node.type == XmlNodeType.PI)
		{
			res ~= "<?" ~ node.rawValue ~ "?>";
		}
		else if(node.type == XmlNodeType.CData)
		{
			res ~= "<![CDATA[" ~ node.rawValue ~ "]]>";
		}
		else if(node.type == XmlNodeType.Doctype)
		{
			res ~= "<!DOCTYPE " ~ node.rawValue ~ ">";
		}
	}
	printNode(root);
	return res;
}

version(Unittest)
{
	void benchmarkSenderoNodeParser (int iterations, char[] filename = "othello.xml") 
	{       
	        uint i;
	        StopWatch elapsed;
	        
	        try {
	            auto file = new File ("../senderoRelease/" ~ filename);
	            auto content = cast(char[]) file.read;
	            
	          //  auto xml = parseXmlTree(content);
	          //  Stdout(print(xml)).newline;

	            elapsed.start;
	            for (i=0; i<iterations; i++)
	            {
	                auto doc = parseXmlTree(content);
                }

	            Stdout.formatln ("sendero: {} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
	            } catch (Object o) 
	                    {
	                    Stdout.formatln ("On iteration: {}", i);
	                    throw o;
	                    } 
	}
	
	import tango.io.Stdout;
	import tango.io.File;
	import tango.time.StopWatch;
	unittest
	{
		//auto doc = parseXmlTree(testXML);
		//Stdout(print(doc)).newline;
		//benchmarkSenderoNodeParser(100, "hamlet.xml");
	}
}