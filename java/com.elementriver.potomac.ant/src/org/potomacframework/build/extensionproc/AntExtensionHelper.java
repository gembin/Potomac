package org.potomacframework.build.extensionproc;

import java.io.File;

import com.elementriver.potomac.shared.ExtensionsHelper;
import com.elementriver.potomac.shared.PType;

import flex2.compiler.SymbolTable;
import flex2.compiler.abc.AbcClass;

public class AntExtensionHelper implements ExtensionsHelper {
	
	private SymbolTable symbolTable;
	private File projectRoot;

	public AntExtensionHelper(SymbolTable symbolTable, File projectRoot) {
		super();
		this.symbolTable = symbolTable;
		this.projectRoot = projectRoot;
	}

	@Override
	public File getProjectRoot() {
		return projectRoot;
	}

	@Override
	public PType getType(String className) {
		if (className.indexOf(":") == -1 && className.indexOf(".") > -1)
		{
			className = className.substring(0,className.lastIndexOf(".")) + ":" + className.substring(className.lastIndexOf(".")+1);
		}
		
		AbcClass clz = symbolTable.getClass(className);
		if (clz == null)
			return null;
		
		return new AntType(clz);
	}

}
