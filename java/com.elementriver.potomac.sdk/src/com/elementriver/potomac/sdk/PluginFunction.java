package com.elementriver.potomac.sdk;

import java.util.ArrayList;
import java.util.List;

import com.adobe.flexbuilder.codemodel.definitions.IArgument;
import com.adobe.flexbuilder.codemodel.definitions.IFunction;
import com.adobe.flexbuilder.codemodel.definitions.IType;
import com.elementriver.potomac.shared.PFunction;
import com.elementriver.potomac.shared.PVariable;

public class PluginFunction extends PFunction
{
	private IFunction fn;
	
	public PluginFunction(IFunction fn)
	{
		super();
		this.fn = fn;
	}

	@Override
	public List<PVariable> getArguments()
	{
		ArrayList<PVariable> args = new ArrayList<PVariable>();
		
		IArgument args2[] = fn.getArguments();
		for (IArgument arg : args2)
		{
			args.add(new PluginVariable(arg));
		}

		return args;
	}

	@Override
	public String getName()
	{
		return fn.getName();
	}

	@Override
	public String getNamespace()
	{
		return fn.getNamespace();
	}

	@Override
	public String getReturnType()
	{
		String retType = fn.getReturnType();
		if (retType.equals("void") || retType.equals("*"))
			return retType;
		
		IType type = fn.resolveReturnType(null);
		if (type == null)
			return retType;
		
		return type.getQualifiedName();
	}

	@Override
	public boolean isConstructor()
	{
		return fn.isConstructor();
	}

}
