package org.potomacframework.build.extensionproc;

import java.util.ArrayList;
import java.util.List;

import com.elementriver.potomac.shared.PFunction;
import com.elementriver.potomac.shared.PVariable;

import flex2.compiler.abc.Method;

public class AntFunction extends PFunction {

	private Method method;
	
	public AntFunction(Method method) {
		super();
		this.method = method;
	}

	public boolean isConstructor()
	{
		String className = method.getDeclaringClass().getName();
		if (className.indexOf(":") > -1)
		{
			className = className.substring(className.indexOf(":")+1);
		}
		return className.equals(method.getQName().toString());
	}
	
	@Override
	public String getName() {
		return method.getQName().toString();
	}

	public String getNamespace() {
		if (method.getAttributes().hasInternal())
			return "internal";
		if (method.getAttributes().hasPrivate())
			return "private";
		if (method.getAttributes().hasProtected())
			return "protected";
		if (method.getAttributes().hasPublic())
			return "public";
		
		return "internal";
	}
	
	public String getReturnType()
	{
		if (isConstructor())
			return method.getDeclaringClass().getName().replaceAll(":", ".");
			
		return method.getReturnTypeName().replaceAll(":", ".");
	}

	public List<PVariable> getArguments()
	{
		ArrayList<PVariable> args = new ArrayList<PVariable>();

		if (method.getParameterNames() == null)
			return args;
		
		for (int i = 0; i < method.getParameterNames().length; i++) {
			args.add(new AntVariable(method.getParameterNames()[i],method.getParameterTypeNames()[i],method.getParameterHasDefault()[i]));
		}
		
		return args;
	}
}
