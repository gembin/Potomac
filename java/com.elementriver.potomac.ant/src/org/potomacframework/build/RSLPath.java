package org.potomacframework.build;

import java.util.ArrayList;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicAttribute;
import org.apache.tools.ant.DynamicElement;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.types.Path;

public class RSLPath extends ProjectComponent implements DynamicAttribute,DynamicElement {

	public ArrayList<RSLURL> getUrls() {
		return urls;
	}

	private Path path;
	private ArrayList<RSLURL> urls = new ArrayList<RSLURL>();
	
	public RSLPath(Project project) {
		setProject(project);
	}

	@Override
	public void setDynamicAttribute(String name, String val)
			throws BuildException {
		if (name.equals("file"))
		{
			path = new Path(getProject(),val);
		}		
	}
	
	public Path getPath()
	{
		return path;
	}

	@Override
	public Object createDynamicElement(String name) throws BuildException {
		if (name.equals("url"))
		{
			RSLURL url = new RSLURL(getProject());
			urls.add(url);
			return url;
		}
		return null;
	}
	

}
