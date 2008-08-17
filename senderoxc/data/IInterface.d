module senderoxc.data.IInterface;

public import sendero.util.Call;

alias Call!("Interface.find", IInterface, char[]).call findInterface; 

interface IInterface
{
	char[] iname();
}