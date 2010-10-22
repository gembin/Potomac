package com.elementriver.potomac.sdk;

import java.io.File;

import org.eclipse.core.resources.IProject;

import com.adobe.flexbuilder.codemodel.definitions.IClass;
import com.adobe.flexbuilder.codemodel.definitions.IInterface;
import com.adobe.flexbuilder.codemodel.indices.IClassNameIndex;
import com.adobe.flexbuilder.codemodel.indices.IInterfaceNameIndex;
import com.elementriver.potomac.shared.ExtensionsHelper;
import com.elementriver.potomac.shared.PType;

public class PluginExtensionsHelper implements ExtensionsHelper
{

	private IProject project;
	private com.adobe.flexbuilder.codemodel.project.IProject flexProject;
	private IClassNameIndex classIndex;
	private IInterfaceNameIndex interfaceIndex;
	
	public PluginExtensionsHelper(IProject project,
			com.adobe.flexbuilder.codemodel.project.IProject flexProject)
	{
		super();
		this.project = project;
		this.flexProject = flexProject;
		
		classIndex = (IClassNameIndex) flexProject.getIndex(IClassNameIndex.ID);
		interfaceIndex = (IInterfaceNameIndex) flexProject.getIndex(IInterfaceNameIndex.ID);
	}
	
	public File getProjectRoot()
	{
		return project.getLocation().toFile();
	}

	public PType getType(String className)
	{
		IClass clz = classIndex.getByQualifiedName(className);
		if (clz != null)
			return new PluginType(clz);
		
		IInterface inter = interfaceIndex.getByQualifiedName(className);
		if (inter != null)
			return new PluginType(inter);
		
		return null;
	}



}
