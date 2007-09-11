/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * License:   BSD Style
 * Authors:   Aaron Craelius
 */

module sendero.util.StringCharIterator;

public import sendero.util.ICharIterator;

import tango.text.Util;

class StringViewer(Ch) : IStringViewer!(Ch)
{
	this(Ch[] text)
	{
		this.text = text;
	}
	
	private Ch[] text;
	
	Ch[] randomAccessSlice(size_t x, size_t y)
	{
		if(x >= text.length)
			return "\0";
		if(y >= text.length)
			return text[x .. $];
		return text[x .. y];
	}
}

class StringCharIterator(Ch) : ICharIterator!(Ch)
{
	this(Ch[] text)
	{
		this.text = text;
		this.len = text.length;
		this.index = 0;
		this.viewer = new StringViewer!(Ch)(text);
		this.p = text.ptr;
	}
	
	private Ch[] text;
	private Ch* p;
	private size_t len;
	private size_t index;
	private StringViewer!(Ch) viewer;
	
	final bool good()
	{
		return index < len;
	}
	
	final Ch opIndex(size_t i)
	{
		version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
                asm
                {
                	align 4;
                	mov EBX, this_;
                	mov ECX, [EBX + index];
                    add ECX, i;
                    
                    mov EAX, [EBX + len];
                    sub EAX, ECX;
                    jng fail;
                    
                    add ECX, [EBX + p];
                    
                    mov AL, [ECX];
                    
                    jmp end;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end:;
                }
            }
            else
            {
            	if((index + i) < len) return text[index + i];
            	else return '\0';
            }
		}
		else
		{
			if((index + i) < len) return text[index + i];
        	else return '\0';
		}
	}
	
	final ICharIterator!(Ch) opAddAssign(size_t i)
	{
		index += i;
		return this;
	}
	
	final ICharIterator!(Ch) opPostInc()
	{
		index++;
		return this;
	}
	
	final ICharIterator!(Ch) opSubAssign(size_t i)
	{
		index -= i;
		return this;
	}
	
	final ICharIterator!(Ch) opPostDec()
	{
		index--;
		return this;
	}
	
	final Ch[] opSlice(size_t x, size_t y)
	{
	/*	version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
				char* p_ = null;
				size_t l_ = 0;
				asm
				{
					mov EBX, this_;
					mov EAX, [EBX + len];
					sub EAX, x;
					jng end;
					
					add EAX, x;
					sub EAX, y;
					jng partialFail;
					
					mov EAX, [EBX + p];
					add EAX, x;
					mov p_, EAX;
					
					mov ECX, y;
					sub ECX, x;
					mov l_, ECX;
					
					jmp end;
					
					partialFail:;
						mov EAX, [EBX + p];
						add EAX, x;
						mov p_, EAX;
						mov ECX, [EBX + len];
						sub ECX, x;
						mov l_, ECX;
					
					end:;
				}
				return p_[0 .. l_];
			}
			else
			{
				if(index + x >= len)
					return "\0";
				if(index + y >= len)
					return text[index + x .. $];
				return text[index + x .. index + y];
			}
		}
		else
		{*/
			if(index + x >= len)
				return "\0";
			if(index + y >= len)
				return text[index + x .. $];
			return text[index + x .. index + y];
		//}
	}
	
	final Ch[] randomAccessSlice(size_t x, size_t y)
	{
		return viewer.randomAccessSlice(x, y);
	}
	
	final size_t location()
	{
		return index;
	}
	
	size_t length()
	{
		return len;
	}
	
	final bool seek(size_t position)
	{
		if(position < length) {
			index = position;
			return true;
		}
		return false;
	}
	
	final IStringViewer!(Ch) src()
	{
		return viewer;
	}
	
	final void reset(Ch[] newText)
	{
		this.text = newText;
		this.len = newText.length;
		this.index = 0;
		this.viewer.text = newText;
		this.p = text.ptr;
	}
	
	final bool forwardLocate(Ch ch)
	{
		auto l = indexOf!(Ch)(text.ptr + index, ch, length - index);
		if(l == length - index) return false;
		index += l;
		return true;
	}
	
	final void forwardLookup(ubyte[256] lookupTable)
	{
		version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
				ubyte* lookup_ = lookupTable.ptr;
				asm
				{
					align 4;
					mov EBX, this_;
					mov ECX, [EBX + len];
					mov EAX, [EBX + index];
					sub ECX, EAX;
                	jng end;
                	
                	add EAX, [EBX + p];           	
                	
                	mov EDI, lookup_;
                	test:;
                		movzx EBX, byte ptr [EAX];
                		add EDI, EBX;
                		mov DL, byte ptr[EDI];
	                	and DL, DL;
	                	jz finish;
	                	sub EDI, EBX;
	                	inc EAX;
	                	loop test;
	                	
	                finish:;
	                	mov EBX, this_;
	                	sub EAX, [EBX + p];
	                	mov [EBX + index], EAX;
	                
	                end:;	
				}
			}
			else
			{
				while(lookupTable[this[0]]) ++this;
			}
		}
		else
		{
			while(lookupTable[this[0]]) ++this;
		}			
	}
}

import tango.io.Stdout;
import tango.io.File;

unittest
{	
	char[] t = "<element attr=\"1\" attr2=\"two\"><!--comment-->test<el2 attr3 = '3three'><![CDATA[sdlgjsh]]><el3 />data<?pi test?></el2></element>";
	auto text = new StringCharIterator!(char)(t);
	uint i = 0;
	while(text.good)
	{
		assert(text[0] == t[i], "res" ~ text[0]);
		++text;
		++i;
	}
}