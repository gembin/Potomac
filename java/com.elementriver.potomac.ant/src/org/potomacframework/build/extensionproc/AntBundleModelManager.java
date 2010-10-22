package org.potomacframework.build.extensionproc;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import org.apache.tools.ant.types.Path;

import com.elementriver.potomac.shared.BundleModel;
import com.elementriver.potomac.shared.BundleModelManager;

public class AntBundleModelManager extends BundleModelManager{
	
	private Path workspacePath;
	private Path targetPlatformPath;	
	private boolean verbose = false;
	
	
	public AntBundleModelManager(Path workspacePath, Path targetPlatformPath,
			boolean verbose)
	{
		super();
		this.workspacePath = workspacePath;
		this.targetPlatformPath = targetPlatformPath;
		this.verbose = verbose;
	}

	
	
	
	public void saveModel(BundleModel model,File toFile) throws IOException
	{
		String xml = getBundleXMLString(model.id,true);		
		
		
	    Writer output = new BufferedWriter(new FileWriter(toFile));
	    try {
	      output.write( xml );
	    }
	    finally {
	      output.close();
	    }
	}

	@Override
	public void fireBundleExtensionChangeEvent(String id)
	{
		//dont need
	}

	@Override
	public ArrayList<String> getAllBundles()
	{
		//dont need
		return null;
	}

	@Override
	public File getBundleXMLFile(String id, boolean binVersion)
	{
		if (verbose)
			System.out.println("Bundle model not cached, loading from bundle.xml.");
		
		File bundlexml = new File(workspacePath.toString() + "/" + id + "/bundle.xml");
		if (!bundlexml.exists())
		{
			bundlexml = new File(targetPlatformPath.toString() + "/" + id + "/bundle.xml");
		}
		
		if (verbose)
			System.out.println("Loading bundle.xml: " + bundlexml.toString());
		
		if (!bundlexml.exists())
		{
			if (verbose)
				System.out.println("File not found.");
			return null;
		}

		return bundlexml;
	}

	@Override
	public void saveModel(String id, boolean binVersion)
	{
		//dont need
		
	}

	
}
