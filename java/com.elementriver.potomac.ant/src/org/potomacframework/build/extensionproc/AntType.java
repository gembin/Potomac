package org.potomacframework.build.extensionproc;

import com.elementriver.potomac.shared.PType;
import flex2.compiler.abc.AbcClass;

public class AntType extends PType {

	private AbcClass abcClass;

	public AntType(AbcClass abcClass) {
		super();
		this.abcClass = abcClass;
	}

	@Override
	public boolean isClass() {
		return !abcClass.isInterface();
	}

	@Override
	public boolean isInstanceOf(String type) {
		if (type.indexOf(":") == -1 && type.indexOf(".") > -1)
		{
			type = type.substring(0,type.lastIndexOf(".")) + ":" + type.substring(type.lastIndexOf(".")+1);
		}
		return abcClass.isSubclassOf(type);
	}

	@Override
	public boolean isInterface() {
		return abcClass.isInterface();
	}

	@Override
	public String getNamespace() {
		return "public";
	}

	@Override
	public String getName() {
		return abcClass.getName().replaceAll(":",".");
	}
	
	
}
