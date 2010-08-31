package org.potomacframework.build.extensionproc;

import com.elementriver.potomac.shared.PVariable;

import flex2.compiler.abc.Variable;

public class AntVariable extends PVariable {
	
	private Variable var;
	private String name;
	private String type;
	private boolean defaultVal;

	public AntVariable(Variable var) {
		super();
		this.var = var;
	}

	public AntVariable(String name,String type,boolean defaultVal) {
		super();
		this.name = name;
		this.type = type.replaceAll(":", ".");
		this.defaultVal = defaultVal;
	}

	@Override
	public String getName() {
		if (var != null)
			return var.getQName().toString().replaceAll(":", ".");
		
		return name;
	}

	
	
	@Override
	public String getType() {
		String val = "";
		if (var != null)
		{
			val = var.getTypeName().replaceAll(":",".");
		}
		else
		{
			val = type;
		}
		
		return val;
	}
	
	

	@Override
	public boolean hasDefault() {
		if (var != null)
			return false;
		
		return defaultVal;
	}

	@Override
	public String getNamespace() {
		if (var != null)
		{
			if (var.getAttributes().hasInternal())
				return "internal";
			if (var.getAttributes().hasPrivate())
				return "private";
			if (var.getAttributes().hasProtected())
				return "protected";
			if (var.getAttributes().hasPublic())
				return "public";
			
			return "internal";
		}
		
		return "private";		
	}

}
