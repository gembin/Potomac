package org.potomacframework.build;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicAttribute;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.types.Path;

public class SourcePath extends ProjectComponent implements DynamicAttribute {

	private Path path;
	
	public SourcePath(Project project) {
		setProject(project);
	}

	@Override
	public void setDynamicAttribute(String name, String val)
			throws BuildException {
		if (name.equals("path-element"))
		{
			path = new Path(getProject(),val);
		}		
	}
	
	public Path getPath()
	{
		return path;
	}
	

}
