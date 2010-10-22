package com.elementriver.potomac.sdk;

import com.adobe.flexbuilder.codemodel.definitions.IClass;
import com.adobe.flexbuilder.codemodel.definitions.IInterface;
import com.adobe.flexbuilder.codemodel.definitions.IType;
import com.elementriver.potomac.shared.PType;

public class PluginType extends PType
{
	private IType flexType;
	
	public PluginType(IType type)
	{
		super();
		this.flexType = type;
	}

	@Override
	public boolean isClass()
	{
		return (flexType instanceof IClass);
	}

	@Override
	public boolean isInstanceOf(String type)
	{
		return flexType.isInstanceOf(type);
	}

	@Override
	public boolean isInterface()
	{
		return (flexType instanceof IInterface);
	}

	@Override
	public String getName()
	{
		return flexType.getQualifiedName();
	}

	@Override
	public String getNamespace()
	{
		return flexType.getNamespace();
	}

}
