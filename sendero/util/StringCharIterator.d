/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
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
	
	final Ch cur()
	{
		/*version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				void* this_ = cast(void*)this;
                asm
                {
                	align 4;
                	mov EBX, this_;
                	mov ECX, [EBX + index];
                    
                    mov EAX, [EBX + len];
                    sub EAX, ECX;
                    jng fail;
                    
                    add ECX, [EBX + p];
                    
                    mov AL, [ECX];
                    
                    jmp end_;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end_:;
                }
			}
            else
			{
				if(index < len) return text[index];
				return '\0';
			}
		}
		else
		{*/
			if(index < len) return text[index];
			return '\0';
		//}
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
                    
                    jmp end_;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end_:;
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
	
	final size_t length()
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
	
	const static ubyte name[64] =
	    [
	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0,];  // 3
	
	 const static ubyte attributeName[64] =
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
		         0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0];  // 3
	
	final bool eatElemName()
	{      
	                Ch* p = text.ptr + index;
	                Ch* end = p + len;

	                while (p < end)
	                      {
	                      Ch c = *p;
	                      if (c > 63 || name[c])
	                          ++p;
	                      else
	                         {
	                         index = p - text.ptr;
	                         return true;
	                         }
	                      }
	                return false;
	    }
	
	final bool eatAttrName()
	{      
	                Ch* p = text.ptr + index;
	                Ch* end = p + len;

	                while (p < end)
	                      {
	                      Ch c = *p;
	                      if (c > 63 || attributeName[c])
	                          ++p;
	                      else
	                         {
	                         index = p - text.ptr;
	                         return true;
	                         }
	                      }
	                return false;
	    }
	
	 const static ubyte whitespace[33] = 
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  0,  1,  0,  0,  // 0
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
		         1];

	    final bool eatSpace()
	    {      
	                Ch* p = text.ptr + index;
	                Ch* end = p + len;

	                while (p < end)
	                      {
	                      if (*p <= 32 && whitespace[*p]) {
	                          ++p;
	                      }
	                      else
	                         {
	                         index = p - text.ptr;
	                         return true;
	                         }
	                      }
	                return false;
	    }

	    //  fill with appropriate bit flags
	    static const ubyte flags[128] =
	    [
	      // 0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	         0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,     // 0
	         0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,     // 1
	         0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,     // 2
	         Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,0,   0,   0,   0,   0,   0,     // 3
	         0,   Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,  // 4
	         Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,0,   0,   0,   0,   Flags.Both,  // 5
	         0,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,     // 6
	         Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,Flags.Both,0,   0,   0,   0,   0,     // 7
	    ];
}

class StringCharIterator2(Ch) : ICharIterator!(Ch)
{
	this(Ch[] text)
	{
		this.text = text;
		this.len = text.length;
		this.index = 0;
		this.viewer = new StringViewer!(Ch)(text);
		this.p = text.ptr;
		this.itr = p;
		//this.left = len
		this.end = p + len;
	}
	
	private Ch[] text;
	private Ch* p;
	private Ch* itr;
	private size_t len;
	private size_t index;
	private Ch* end;
	private StringViewer!(Ch) viewer;
	
	final bool good()
	{
		//return left > 0;
		return itr < end;
	}
	
	final Ch cur()
	{
		version(D_InlineAsm_X86)
		{
			static if (Ch.sizeof == 1)
			{
				StringCharIterator2!(Ch) this_ = this;
				asm
				{
					mov EBX, this_;
                	mov ECX, [EBX + end];
                    mov EDX, [EBX + itr];
                    sub ECX, EDX;
                    jng fail;
                    
                    mov EAX, [EDX];
                    jmp end_;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end_:;
				}
			}
			else
			{
				if(itr > end) return *itr;
				return '\0';
			}
		}
		else
		{
			if(itr > end) return *itr;
			return '\0';
		}
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
                	mov EBX, this_;
                	mov EDX, [EBX + itr];
                	add EDX, i;
                	mov ECX, [EBX + end];
                	sub ECX, EDX;
                	jng fail;
                	
                    mov EAX, [EDX];
                    
                    jmp end_;
                    
                    fail:;
                    	xor EAX, EAX;
                    	
                    end_:;
                }
            }
            else
            {
            	if(left - i > 0) return *(itr + i);
				return '\0';
            }
		}
		else
		{
			if(left - i > 0) return *(itr + i);
			return '\0';
		}
	}
	
	final ICharIterator!(Ch) opAddAssign(size_t i)
	{
		itr += i;
		return this;
	}
	
	final ICharIterator!(Ch) opPostInc()
	{
		++itr;
		return this;
	}
	
/*	final ICharIterator!(Ch) opSubAssign(size_t i)
	{
		itr -= i;
		left += i;
		return this;
	}
	
	final ICharIterator!(Ch) opPostDec()
	{
		--itr;
		++left;
		return this;
	}*/
	
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
			if(itr >= end || y <= x) return "\0";
			if(itr + y >= end)
				return "\0";
			return itr[x .. y];
		//}
	}
	
	final Ch[] randomAccessSlice(size_t x, size_t y)
	{
		return viewer.randomAccessSlice(x, y);
	}
	
	final size_t location()
	{
		//return index;
		//return itr - p;
		return itr - p;
	}
	
	size_t length()
	{
		return len;
	}
	
	final bool seek(size_t position)
	{
		if(position < length) {
			//index = position;
			itr = p + position;
			//left = len - position;
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
		this.itr = p;
		//this.left = len;
		this.end = p + len;
	}
	
	final bool forwardLocate(Ch ch)
	{
		/*version (D_InlineAsm_X86)
        {       
                static if (Ch.sizeof == 1)
                {
                	StringCharIterator2!(Ch) this_ = this;
                	asm
                	{
                		mov   EBX, this_;
                		mov   EDI, [EBX + itr];
                        mov   ECX, [EBX + left];
                        jz    fail2;  
                        movzx EAX, ch;
                        mov   ESI, ECX;
                        //and   ESI, ESI;
                             

                        cld;
                        repnz;
                        scasb;
                        jnz   fail2;
                        sub   ESI, ECX;
                        dec   ESI;
                        mov   [EBX + left], ESI;
                        mov   [EBX + itr], EDI;
                        
                        mov EAX, 1;
                        jmp end;
                     
                    fail1:
                    	mov   [EBX + left], 0;
                    fail2:;
                        xor   EAX, EAX;
                    end:;
                        //mov   EAX, ESI;
                	}
                }
                else
                {
                	auto l = indexOf!(Ch)(itr, ch, left);
        			if(l == left) return false;
        			itr += l;
        			left -= l;
        			return true;
                }
        }
		else
		{*/
			auto l = indexOf!(Ch)(itr, ch, end - itr);
			if(l == end - itr) return false;
			itr += l;
			return true;
		//}
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
					mov EBX, this_;
					mov EDX, [EBX + itr];
					mov ECX, [EBX + end];
					sub ECX, EDX;
					jng end_;
                	                	
                    mov EDI, lookup_;
                	test:;
                		movzx EAX, byte ptr [EDX];
                		add EDI, EAX;
                		mov BL, byte ptr[EDI];
	                	and BL, BL;
	                	jz finish;
	                	sub EDI, EAX;
	                	inc EDX;
	                	loop test;
	                	
	                finish:;
	                	mov EBX, this_;
	                	mov [EBX + itr], EDX;
	                
	                end_:;	
				}
			}
			else
			{
				while(itr < end && lookupTable[*itr]) {++itr;}
			}
		}
		else
		{
			while(itr < end && lookupTable[*itr]) {++itr;}
		}			
	}
	
	const static ubyte name[64] =
	    [
	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  1,  1,  0,  0,];  // 3
	
	 const static ubyte attributeName[64] =
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  1,  1,  0,  1,  1,  // 0
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 1
		         0,  0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  // 2
		         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  1,  0,  0,  0,  0];  // 3
	
	final bool eatElemName()
	{      
	              while (itr < end)
	                      {
	                      Ch c = *itr;
	                      if (c > 63 || name[c])
	                          ++itr;
	                      else
	                         {
	                         return true;
	                         }
	                      }
	                return false;
	    }
	
	final bool eatAttrName()
	{      
	               while (itr < end)
	                      {
	                      Ch c = *itr;
	                      if (c > 63 || attributeName[c])
	                          ++itr;
	                      else
	                         {
	                        return true;
	                         }
	                      }
	                return false;
	    }
	
	 const static ubyte whitespace[33] = 
		    [
		      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  0,  1,  0,  0,  // 0
		         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
		         1];

	    final bool eatSpace()
	    {      
	                while (itr < end)
	                      {
	                      if (*itr <= 32 && whitespace[*itr]) {
	                          ++itr;
	                      }
	                      else
	                         {
	                         return true;
	                         }
	                      }
	                return false;
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