package org.potomacframework.build;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicAttribute;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectComponent;

public class RSLURL extends ProjectComponent implements DynamicAttribute {

	private String rslURL ="";
	private String policyURL = "";
	
	public RSLURL(Project project) {
		setProject(project);
	}

	@Override
	public void setDynamicAttribute(String name, String val)
			throws BuildException {
		if (name.equals("rsl-url"))
		{
			rslURL = val;
		}		
		else if (name.equals("policy-file-url"))
		{
			policyURL = val;
		}
	}

	public String getRslURL() {
		return rslURL;
	}

	public String getPolicyURL() {
		return policyURL;
	}
	

	

}
