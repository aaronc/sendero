module sendero.validation.ValidationReflector;

import sendero.validation.Validation;
import sendero.vm.ExecutionContext;
/+
class ReflectedTrait
{
	char[] property;
	char[] value;
	char[] errCode;
}

class ValidationReflection
{
	static ValidationReflection getValidation(char[] className)
	{
		auto pvr = className in validations;
		if(pvr) {
			return *pvr;
		}
		
		auto valRefl = new ValidationReflection;
		
		auto pv = className in ValidationInspector.registeredValidations;
		for(uint i = 0; i < pv.fields.length; ++i)
		{
			ReflectedTrait[] res;
			foreach(opt; pv.options[i])
			{
				auto valTraits = opt.validator.getTraits;
				foreach(t; valTraits)
				{
					ReflectedTrait rtrait;
					rtrait.property = t.property;
					rtrait.value = t.value;
					rtrait.errCode = opt.errCode;
					res ~= rtrait;
				}
			}
			
			valRefl.traits[pv.fields[i].name] = res;
		}
		
		validations[className] = valRefl;
		return valRefl;
	}
	private static ValidationReflection[char[]] validations;
	
	ReflectedTrait[][char[]] traits;
}

class ValidationReflector : IFunctionBinding
{
	static this()
	{
		FunctionBindingContext.global.addFunction("getValidation", new ValidationReflector);
	}
	
	Var exec(Var[] params, ExecutionContext ctxt)
	{
		if(params.length < 1)
			return Var();
		
		if(params[0].type != VarT.String)
			return Var();
		
		auto refl = ValidationReflection.getValidation(params[0].string_);
		
		Var res;
		
		if(params.length < 2 || params[1].type != VarT.String) {
			res = refl.traits;
			return res;
		}
		
		auto pVal = params[1].string_ in refl.traits;
		if(!pVal)
			return Var();
		
		res = *pVal;
		
		return res;
	}
}+/