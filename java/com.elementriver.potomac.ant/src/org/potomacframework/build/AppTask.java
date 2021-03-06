package org.potomacframework.build;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipFile;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicConfigurator;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Path;
import org.potomacframework.build.extensionproc.AntManifestModel;

import com.elementriver.potomac.shared.BundleModel;
import com.elementriver.potomac.shared.ExtensionsMetadataProcessor;

import flex2.tools.oem.Application;
import flex2.tools.oem.Configuration;

public class AppTask extends Task implements DynamicConfigurator {
	
	private Path filePath; //main mxml file
	
	private List<SourcePath> srcPaths = new ArrayList<SourcePath>();
	private List<LibraryPath> libPaths = new ArrayList<LibraryPath>();
	private List<RSLPath> rslPaths = new ArrayList<RSLPath>();

	
	private Path outputPath;	

	private String id;
	private Path sdkPath;
	
	private boolean accessible = false;
	private boolean debug = false;
	private boolean verbosestacktraces = false;
	
	private Path workspacePath;
	private Path targetPlatformPath;
		
	private boolean verbose = false;
	
	public String currentBundleDirectory = "";
	public String currentBundle = "";

	private List<LoadConfig> loadConfigs = new ArrayList<LoadConfig>();
	
	private String locale;
	
	public void setId(String id)
	{
		this.id = id;
	}
	
	public void setVerbosestacktraces(boolean verbosestacktraces)
	{
		this.verbosestacktraces = verbosestacktraces;
	}
	
	public void setAccessible(boolean accessible)
	{
		this.accessible = accessible; 
	}
	
	public void setDebug(boolean debug)
	{
		this.debug = debug;
	}
	
	public void setVerbose(boolean verbose)
	{
		this.verbose = verbose;
	}
	
	public void setFile(Path p)
	{
		filePath = p;
	}
	
	public void setLocale(String l)
	{
		this.locale = l;
	}
	
	@Override
	public void execute() throws BuildException 
	{
		if (verbose)
			System.out.println("Application task starting for '"+id+"'");
		
		String work = getProject().getProperty("POTOMAC_WORKSPACE_HOME");
		if (work == null)
			throw new BuildException("POTOMAC_WORKSPACE_HOME property not set.");
		
		workspacePath = new Path(getProject(),work);
		
		String target = getProject().getProperty("POTOMAC_TARGET_PLATFORM");
		if (target == null)
			throw new BuildException("POTOMAC_TARGET_PLATFORM property not set.");
		
		targetPlatformPath = new Path(getProject(),target);
		
		String output = getProject().getProperty("POTOMAC_BUILD_OUTPUT");
		if (output == null)
			throw new BuildException("POTOMAC_BUILD_OUTPUT property not set.");
		
		outputPath = new Path(getProject(),output);
		
		if (id == null)
			throw new BuildException("Application id not specified.");
		
		if (!new File(workspacePath.toString() + "/" + id).exists())
			throw new BuildException("Application '"+id+"' not found in workspace home.");
		
		String sdk = getProject().getProperty("FLEX_HOME");
		if (sdk == null)
			throw new BuildException("FLEX_HOME property not set.");
		
		sdkPath = new Path(getProject(),sdk);
		
		if (srcPaths.size() == 0)
			throw new BuildException("No source-paths specified.");
		
		if (verbose)
			System.out.println("Properties validated.  Building App.");
		
		
		
		/**
		 * validate appManifest
		 * -UI template is selected
		 * -make sure all bundles found (and all bundles depends are found too)
		 * -ensure required RSL are RSL
		 * 
		 */
		
		if (verbose)
			System.out.println("Validating appManifest.xml");
		
		AntManifestModel model = new AntManifestModel(new File(workspacePath.toString() + "/" + id + "/appManifest.xml"),BundleTask.bundleModelManager);
		
		if (model.templateID == null || model.templateID.trim().length() == 0)
			throw new BuildException("Template ID not specified in appManifest.xml.");
		
		HashMap<String,String> templateExt = null;
		
		for (String depend : model.bundles)
		{
			BundleModel bundleModel = BundleTask.bundleModelManager.getModel(depend);
			for (HashMap<String,String> ext : bundleModel.extensions)
			{
				if (ext.get("point").equals("Template") && ext.get("id").equals(model.templateID))
				{
					templateExt = ext;
					break;
				}
			}
		}
		
		if (templateExt == null)
			throw new BuildException("Template ID specified '" + model.templateID + "' not found within application's bundles.");
		
		if (verbose)
			System.out.println("Template verified.");
		
		for (String bundle : model.bundles)
		{			
			BundleModel bundleModel = BundleTask.bundleModelManager.getModel(bundle);
			
			//ensure dependencies are all found
			for (String depend : bundleModel.dependencies)
			{
				if (!model.bundles.contains(depend))
				{
					throw new BuildException("Bundle '" + bundle + "' depends on bundle '" + depend +"' which is not included in the application's bundle list.");
				}
			}
	
			//ensure this bundle is an RSL if one of its extensions is an RSL only extension
			for (HashMap<String,String> ext : bundleModel.extensions)
			{
				//Find ext pt for this ext
				HashMap<String,String> extPt = null;
				
				for (String subDepend : model.bundles)
				{
					BundleModel subDependModel = BundleTask.bundleModelManager.getModel(subDepend);
					
					for (HashMap pt : subDependModel.extensionPoints) 
					{
						if (pt.get("id").equals(ext.get("point")))
						{
							extPt = pt;
							break;
						}
					}
				}
				
				if (extPt == null)
					throw new BuildException("Error during RSL extension processing.  Extension point '" + ext.get("point") +"' not found.");
				
				if (!model.preloads.contains(bundle) && extPt.get("preloadRequired") != null && extPt.get("preloadRequired").equals("true"))
				{
					throw new BuildException("Bundle '" + bundle +"' must be preloaded.  It contains one or more extensions only valid for preloaded bundles.");
				}
			}
		}
	
		if (verbose)
			System.out.println("appManifest.xml verified");
		
		//do bundle copy
		
		for (String bundle : model.bundles)
		{
			
			File bundleFolder = new File(outputPath.toString() + "/" + bundle);
			if (!bundleFolder.exists())
				bundleFolder = new File(targetPlatformPath.toString() + "/" + bundle);
			
			if (!bundleFolder.exists())
				throw new BuildException("Unable to find bundle '"+ bundle + "' in either output directory or target platform.");

			File toDir = new File(outputPath.toString() + "/" + id + "/bundles/"+bundle);
			
			try {
				copyDirectory(bundleFolder, toDir);
			} catch (IOException e) {
				e.printStackTrace();
				throw new BuildException(e);
			}
		}
		
		if (verbose)
			System.out.println("Bundles copied.");
				

		File derivedDir = new File(srcPaths.get(0).getPath().toString() + "/potomac/derived");
		if (!derivedDir.exists())
			derivedDir.mkdir();
		
		String newline = System.getProperty("line.separator");
		
	
		
		//create Poto Initer
		
		String appInitSrc = ExtensionsMetadataProcessor.getAppInitializerSource(model, workspacePath.toString() + "/" + id + "/");
		
		
		
		File pInit = new File(derivedDir,"PotomacInitializer.as");
		
	    try {
			Writer pInitOutput = new BufferedWriter(new FileWriter(pInit));
			try {
				pInitOutput.write(appInitSrc.toString());
			}
			finally {
				pInitOutput.close();
			}
		} catch (IOException e) {
			throw new BuildException(e);
		}
		
		
		if (verbose)
			System.out.println("PotomacInitializer.as created.");
		
		if (verbose)
			System.out.println("Configuring MXML Builder");
		
		
		Application app = null;
		try {
			File mxml = new File(filePath.toString());
			app = new Application(mxml);
			File swf = new File(outputPath.toString() + "/" + id + "/" + mxml.getName().substring(0, mxml.getName().length()-5)+".swf");
			app.setOutput(swf);
		} catch (FileNotFoundException e) {
			throw new BuildException("File '" + filePath.toString() + "' not found.");
		}
		
		try {
			app.setConfiguration(app.getDefaultConfiguration());
			configureConfiguration(app.getConfiguration(),model,id);
		} catch (NullPointerException e) {
			e.printStackTrace();
			throw e;
		}

		app.setLogger(new PLogger());
		
		
		if (verbose)
			System.out.println("Building SWF.");
		
		try {
			if (app.build(false) <= 0)
			{
				throw new BuildException("SWF Build Failed.");
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new BuildException(e);
		}
		
		if (verbose)
			System.out.println("SWF Built.");
		
		if (verbose)
			System.out.println("Extracting core bundle RSLs.");
		
		
		String rslBundle = "potomac_core";

		File swf = new File(outputPath.toString() + "/" + id + "/" + rslBundle + ".swf");

		File swc = new File(outputPath.toString() + "/" + rslBundle + "/" + rslBundle + ".swc");
		if (!swc.exists())
			swc = new File(targetPlatformPath.toString() + "/" + rslBundle + "/" + rslBundle + ".swc");
		
		ZipFile swcZip;
		try {
			swcZip = new ZipFile(swc);
		} catch (ZipException e) {
			throw new BuildException(e);
		} catch (IOException e) {
			throw new BuildException(e);
		}
		ZipEntry libswf = swcZip.getEntry("library.swf");
		
		try {
			InputStream zipStream = swcZip.getInputStream(libswf);
			
			FileOutputStream outStream = new FileOutputStream(swf);             
			int n;
			byte[] buf = new byte[1024];
			
			 while ((n = zipStream.read(buf, 0, 1024)) > -1)
			     outStream.write(buf, 0, n);

			 outStream.close(); 
			 zipStream.close();
		} catch (FileNotFoundException e) {
			throw new BuildException(e);
		} catch (IOException e) {
			throw new BuildException(e);
		}

		
	}
	
	private void configureConfiguration(Configuration config, AntManifestModel model,String id)
	{
		if (loadConfigs.size() == 0)
		{
			config.setConfiguration(new File(sdkPath.toString() + "/frameworks/flex-config.xml"));
		}
		else
		{
			config.setConfiguration(new File(loadConfigs.get(0).getPath().toString()));
			for (int i = 1; i < loadConfigs.size(); i++)
			{
				config.addConfiguration(new File(loadConfigs.get(i).getPath().toString()));
			}
		}
		
		config.setLocale(new String[]{});
		config.enableDebugging(debug,"");
		config.enableVerboseStacktraces(verbosestacktraces);
		for(SourcePath sp : srcPaths)
		{
			config.addSourcePath(new File[]{new File(sp.getPath().toString())});
		}
		config.keepAllTypeSelectors(true);	
		config.setLocalFontSnapshot(new File(sdkPath.toString()+"/frameworks","localFonts.ser"));
		

		config.enableAccessibility(accessible);
		
		//config.setExternalLibraryPath(new File[]{});
		config.setLibraryPath(new File[]{});
		config.setRuntimeSharedLibraries(new String[]{});
		config.setRuntimeSharedLibraryPath("", new String[]{}, new String[]{});
	
		for (LibraryPath lp : libPaths)
		{
			config.addLibraryPath(new File[]{new File(lp.getPath().toString())});
		}
		
		for (RSLPath rsl : rslPaths)
		{
			ArrayList<String> rslURL = new ArrayList<String>();
			ArrayList<String> policyURL = new ArrayList<String>();
			for (RSLURL url : rsl.getUrls())
			{
				rslURL.add(url.getRslURL());
				policyURL.add(url.getPolicyURL());
			}
			
			config.addRuntimeSharedLibraryPath(rsl.getPath().toString(), rslURL.toArray(new String[]{}),policyURL.toArray(new String[]{}));
		}
		
		String rslBundle = "potomac_core";

		File swc = new File(outputPath.toString() + "/" + rslBundle + "/" + rslBundle + ".swc");
		if (!swc.exists())
			swc = new File(targetPlatformPath.toString() + "/" + rslBundle + "/" + rslBundle + ".swc");
		
		config.addRuntimeSharedLibraryPath(swc.getAbsolutePath(), new String[]{rslBundle + ".swf"},new String[]{""});
		
		if (locale == null)
		{
			config.setLocale(new String[]{});
		}
		else
		{
			config.setLocale(new String[]{locale});
		}	
		
	}

	
	@Override
	public void setDynamicAttribute(String arg0, String arg1) throws BuildException 
	{	
		System.out.println("Unknown attribte: " +arg0);
	}

	@Override
	public Object createDynamicElement(String name) throws BuildException 
	{
		if (name.equals("source-path"))
		{
			SourcePath sp = new SourcePath(getProject());
			srcPaths.add(sp);
			return sp;
		}
		
		if (name.equals("library-path"))
		{
			LibraryPath lp = new LibraryPath(getProject());
			libPaths.add(lp);
			return lp;
		}
		
		if (name.equals("rsl-path"))
		{
			RSLPath rslPath = new RSLPath(getProject());
			rslPaths.add(rslPath);
			return rslPath;
		}
		
		if (name.equals("load-config"))
		{
			LoadConfig lc = new LoadConfig(getProject());
			loadConfigs.add(lc);
			return lc;
		}
		
		return null;
	}

	private void copyDirectory(File sourceLocation, File targetLocation) throws IOException 
	{

		if (sourceLocation.isDirectory()) {
			
			if (!targetLocation.exists())
				targetLocation.mkdir();

			String[] children = sourceLocation.list();
			for (int i = 0; i < children.length; i++) 
			{
				File kid = new File(sourceLocation, children[i]);
				if (!kid.isHidden() && !kid.getName().startsWith("."))
					copyDirectory(kid, new File(targetLocation, children[i]));
			}
			
		} else {

			targetLocation.getParentFile().mkdirs();
			
			InputStream in = new FileInputStream(sourceLocation);
			OutputStream out = new FileOutputStream(targetLocation);

			// Copy the bits from instream to outstream
			byte[] buf = new byte[1024];
			int len;
			while ((len = in.read(buf)) > 0) {
				out.write(buf, 0, len);
			}
			in.close();
			out.close();
		}
	}
	
}
