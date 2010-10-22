package com.elementriver.potomac.shared;

import java.util.List;

public class PFunction extends PDefinition {

	public boolean isConstructor()
	{
		return false;
	}
	
	@Override
	public String getName() {
		return null;
	}

	public String getNamespace() {
		return null;
	}
	
	public String getReturnType()
	{
		return null;
	}

	public List<PVariable> getArguments()
	{
		return null;
	}

}
