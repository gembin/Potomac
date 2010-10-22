package com.elementriver.potomac.sdk;

import com.adobe.flexbuilder.codemodel.definitions.IArgument;
import com.adobe.flexbuilder.codemodel.definitions.IVariable;
import com.elementriver.potomac.shared.PVariable;

public class PluginVariable extends PVariable
{
	private IVariable var;
	
	
	
	public PluginVariable(IVariable var)
	{
		super();
		this.var = var;
	}

	@Override
	public String getName()
	{
		return var.getName();
	}

	@Override
	public String getType()
	{
		return var.getVariableType();
	}

	@Override
	public boolean hasDefault()
	{
		if (var instanceof IArgument)
		{
			return ((IArgument)var).getDefaultValue() != null;
		}
		return false;
	}

	@Override
	public String getNamespace()
	{
		return var.getNamespace();
	}

}
