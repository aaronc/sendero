module senderoxc.data.IInterface;

public import sendero.util.Call;

import decorated_d.core.Declarations;

alias Call!("Interface.find", IInterface, char[]).call findInterface; 

interface IInterfaceWriter
{
	void addInterface(char[] interfaceName, char[][] imports = null);
	void addMethod(FunctionDeclaration decl);
}

interface IInterface : IInterfaceWriter
{
	char[] iname();
}