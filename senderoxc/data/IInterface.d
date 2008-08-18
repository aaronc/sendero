module senderoxc.data.IInterface;

public import sendero.util.Call;

import decorated_d.core.Declarations;

alias Call!("Interface.find", IInterface, char[]).call findInterface; 

interface IInterface
{
	char[] iname();
	void addInterface(char[] interfaceName, char[][] imports = null);
	void addMethod(FunctionDeclaration decl);
}