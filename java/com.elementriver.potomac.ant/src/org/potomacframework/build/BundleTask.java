package org.potomacframework.build;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicConfigurator;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Path;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import flex2.tools.oem.Application;
import flex2.tools.oem.Configuration;
import flex2.tools.oem.Library;
import flex2.tools.oem.Report;
import flex2.tools.oem.VirtualLocalFile;
import flex2.tools.oem.VirtualLocalFileSystem;

public class BundleTask extends Task implements DynamicConfigurator {
	
	private static ArrayList<BundleModel> bundleModels = new ArrayList<BundleModel>();
	
	private static Path workspacePath;
	private static Path targetPlatformPath;
	
	private static boolean verbose = false;
	
	public static String currentBundleDirectory = "";
	public static String currentBundle = "";
	
	public static BundleModel getModel(String bundle)
	{
//		if (verbose)
//			System.out.println("Retrieving Bundle Model for '"+bundle+"'.");
		
		for (BundleModel model : bundleModels)
		{
			if (model.id.equals(bundle))
				return model;
		}
		
		if (verbose)
			System.out.println("Bundle model not cached, loading from bundle.xml.");

		File bundlexml = new File(workspacePath.toString() + "/" + bundle + "/bundle.xml");
		if (!bundlexml.exists())
		{
			bundlexml = new File(targetPlatformPath.toString() + "/" + bundle + "/bundle.xml");
		}
		
		if (verbose)
			System.out.println("Loading bundle.xml: " + bundlexml.toString());
		
		if (!bundlexml.exists())
		{
			if (verbose)
				System.out.println("File not found.");
			return null;
		}
		
		BundleModel model = loadBundleModel(bundlexml);
		
		bundleModels.add(model);
		
		return model;
	}
	
	private static BundleModel loadBundleModel(File bundlexml)
	{
		final BundleModel model = new BundleModel();		
		
		try {
			SAXParser parser = SAXParserFactory.newInstance().newSAXParser();
			
			parser.parse(bundlexml,new DefaultHandler() {
				
				boolean inDependencies = false;
				boolean inBundle = false;
				
				public void startElement(String uri, String localName, String name,
						Attributes attributes) throws SAXException {
					if (name.equals("bundle"))
					{
						inBundle = true;
						if (!inDependencies)
						{
							model.id = attributes.getValue("id");
							model.name = attributes.getValue("name");
							model.activator = attributes.getValue("activator");
							model.version = attributes.getValue("version");
						}
					}
					if (name.equals("requiredBundles"))
					{
						inDependencies = true;
					}
					if (name.equals("extensionPoint"))
					{
						HashMap<String,String> extPt = new HashMap<String,String>();
						for (int i = 0; i < attributes.getLength(); i++) {
							extPt.put(attributes.getQName(i),attributes.getValue(i));
						}
						model.extensionPoints.add(extPt);
					}
					if (name.equals("extension"))
					{
						HashMap<String,String> ext = new HashMap<String,String>();
						for (int i = 0; i < attributes.getLength(); i++) {
							ext.put(attributes.getQName(i),attributes.getValue(i));
						}
						model.extensions.add(ext);						
					}
				}

				public void endElement(String uri, String localName, String name)
						throws SAXException {
					if (name.equals("requiredBundles"))
					{
						inDependencies = false;
					}
					if (name.equals("bundle"))
					{
						inBundle = false;
					}
				}

				public void characters(char[] ch, int start, int length)
						throws SAXException {
					if (inDependencies && inBundle && new String(ch,start,length).trim().length() > 0)
					{
						model.dependencies.add(new String(ch,start,length).trim());
					}
				}
								
			});
		} catch (ParserConfigurationException e) {
			throw new BuildException(e);
		} catch (SAXException e) {
			throw new BuildException(e);
		} catch (IOException e) {
			throw new BuildException(e);
		}
		
		return model;
	}
	
	public static boolean isVerbose()
	{
		return verbose;
	}
	

	private Path outputPath;	

	private String id;
	private Path sdkPath;
	
	private boolean accessible = false;
	private boolean debug = false;
	
	private List<SourcePath> srcPaths = new ArrayList<SourcePath>();
	private List<LibraryPath> libPaths = new ArrayList<LibraryPath>();
	private List<ExternalLibraryPath> extPaths = new ArrayList<ExternalLibraryPath>();

	private LoadConfig loadConfig;
	
	private String locale;
	
	private String bundleVersion;

	public void setId(String id)
	{
		this.id = id;
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
	
	public void setLocale(String l)
	{
		this.locale = l;
	}
	
	public void setVersion(String ver)
	{
		this.bundleVersion = ver;
	}
	
	@Override
	public void execute() throws BuildException 
	{
	
		if (verbose)
			System.out.println("Bundle task starting for '"+id+"'");
		
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
		
		
		String antJarPath = getProject().getProperty("POTOMAC_ANT_JAR");
		if (antJarPath == null)
			throw new BuildException("POTOMAC_ANT_JAR property not set.");
		
		if (id == null)
			throw new BuildException("Bundle id not specified.");
		
		if (!new File(workspacePath.toString() + "/" + id).exists())
			throw new BuildException("Bundle '"+id+"' not found in workspace home.");
		
		String sdk = getProject().getProperty("FLEX_HOME");
		if (sdk == null)
			throw new BuildException("FLEX_HOME property not set.");
		
		sdkPath = new Path(getProject(),sdk);
		
		if (srcPaths.size() == 0)
			throw new BuildException("No source-paths specified.");
		
		if (verbose)
			System.out.println("Properties validated.  Building SWC.");
		
		
		currentBundleDirectory = workspacePath.toString() + "/" + id;
		currentBundle = id;

		//*******************************BUILD SWC********************************************
		Library bundleLib = new Library();
		
		bundleLib.setConfiguration(bundleLib.getDefaultConfiguration());
		Configuration config = bundleLib.getConfiguration();
		
		configureConfiguration(config);
		
		if (verbose)
			System.out.println("Configured Library Builder.");
		
		File outputDir = new File(outputPath.toString() + "/" + id);
		if (!outputDir.exists())
			outputDir.mkdir();

		
		bundleLib.setOutput(new File(outputPath.toString() + "/" + id + "/" + id+ ".swc"));
		
		bundleLib.setLogger(new PLogger());
		
		for(SourcePath sp : srcPaths)
		{
			File spFile = new File(sp.getPath().toString());
			if (spFile.exists())
				recursiveAddComponent(spFile, bundleLib);
		}
		

		try {
			if (bundleLib.build(true) <= 0)
			{
				throw new BuildException("SWC Build Failed.");
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new BuildException("Build Failed",e);
		}
		
		if (verbose)
			System.out.println("SWC Built.");
		
		ArrayList<String> classes = new ArrayList<String>();
		
		Report report = bundleLib.getReport();
		String[] sources = report.getSourceNames(Report.LINKER);
		
		for(String src : sources)
		{
			String[] defs = report.getDefinitionNames(src);
			if (defs == null)
				continue;
			
			for (String def : defs)
			{
				classes.add(def);
			}
		}
		
		if (verbose)
			System.out.println("Building SWF.");
		
		//*******************************BUILD SWF********************************************
		VirtualLocalFileSystem fs = new VirtualLocalFileSystem();

		File sourceDir = new File(srcPaths.get(0).getPath().toString());
		
		String moduleName = id + "PotomacModule";
		
		String moduleClass = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
								"<mx:Module xmlns:mx=\"http://www.adobe.com/2006/mxml\" layout=\"absolute\" width=\"100\" height=\"100\">" +
								"</mx:Module>";
		
		if (verbose)
			System.out.println("Creating virtual module class.");
		
		VirtualLocalFile moduleFile;
		try {
			moduleFile = fs.create(new File(sourceDir, moduleName + ".mxml").getCanonicalPath(), moduleClass, sourceDir, System.currentTimeMillis());
		} catch (IOException e) {
			throw new BuildException(e);
		}
		
		Application bundleApp = new Application(moduleFile);
		bundleApp.setConfiguration(bundleApp.getDefaultConfiguration());
		config = bundleApp.getConfiguration();
		
		if (verbose)
			System.out.println("Configuring Application Builder.");
		
		configureConfiguration(config);
		
		if (verbose)
			System.out.println("Application Builder Configured.");
			
		bundleApp.setOutput(new File(outputPath.toString() + "/" + id + "/" + id+ ".swf"));
		
		bundleApp.setLogger(new PLogger());
		
		config.setIncludes(classes.toArray(new String[]{}));

		List<String> extensions = new ArrayList<String>();
		bundleApp.getConfiguration().addExtensionLibraries(new File(antJarPath), extensions);
		

		try {
			if (bundleApp.build(true) <= 0)
			{
				throw new BuildException("SWF Build Failed.");
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new BuildException("Build Failed",e);
		}

		if (verbose)
			System.out.println("SWF Built.");
		
		File outputBundleXML = new File(outputPath.toString() + "/" + id + "/bundle.xml");
		
		BundleModel model = getModel(id);
		
		if (bundleVersion != null)
			model.version = bundleVersion;
		
		try {
			BundleModelManager.saveModel(model, outputBundleXML);
		} catch (IOException e) {
			throw new BuildException(e);
		}
		
		
		//*******************************Copy Assets********************************************
		File extensionAssetsFolder = new File(workspacePath.toString() + "/" + id + "/extensionAssets");
		File assetsFolder = new File(outputPath.toString() + "/" + id + "/assets" );
		if (extensionAssetsFolder.exists())
		{
			if (!assetsFolder.exists());
			{
				assetsFolder.mkdir();
			}
			
			try {
				copyDirectory(extensionAssetsFolder, assetsFolder);
			} catch (IOException e) {
				throw new BuildException(e);
			}
		}
		
		
		//************************** Create assets.swf ********************************
		if (verbose)
			System.out.println("Building assets.swf");

		
		String className = "PotomacAssets_"+id;
		
		String assetsClass = "package{ import flash.display.Sprite; public class " + className + " extends Sprite {";
		
		String newLine = System.getProperty("line.separator");
		
		assetsClass += newLine + newLine;
		
		String path = outputPath.toString() + "/" + id + "/bundle.xml";
		
		path = path.replace('\\','/');
		assetsClass += "[Embed(source=\""+path+"\",mimeType=\"application/octet-stream\")]" +newLine;;
		
		String varName = "bundlexml";
		
		assetsClass += "public var "+varName+":Class;";
		
		assetsClass += newLine + newLine;
		
		for (String asset : model.extensionAssets)
		{
			path = asset;
			
			path = path.replace('\\','/');
			assetsClass += "[Embed(source=\""+path+"\")]" +newLine;;
			
			varName = asset;
			varName = varName.substring(currentBundleDirectory.length() + 1);
			varName = varName.replace('/','_');
			varName = varName.replace('.','_');
			varName = varName.replace(' ','_');
			varName = varName.replace('\\','_');
			
			assetsClass += "public var "+varName+":Class;";
			
			assetsClass += newLine + newLine;
		}
		
		assetsClass += newLine + newLine;
		
		assetsClass += "}}";

		VirtualLocalFile assetsVF;
		try {
			VirtualLocalFileSystem fs2 = new VirtualLocalFileSystem();
			assetsVF = fs2.create(new File(sourceDir, className + ".as").getCanonicalPath(), assetsClass, sourceDir, System.currentTimeMillis());
		} catch (IOException e) {
			throw new BuildException("Error during Potomac build (assets).", e);
		}

		
		Application assetApp = new Application(assetsVF);
		Configuration assetsConfig = assetApp.getDefaultConfiguration();
		
		if (loadConfig == null)
		{
			assetsConfig.setConfiguration(new File(sdkPath.toString() + "/frameworks/flex-config.xml"));
		}
		else
		{
			assetsConfig.setConfiguration(new File(loadConfig.getPath().toString()));
		}
		
		assetsConfig.addExternalLibraryPath(new File[]{new File(sdkPath.toString() + "/frameworks/libs/flex.swc")});
		assetsConfig.setLibraryPath(new File[]{});
		assetsConfig.setLocale(new String[]{});
		assetsConfig.setRuntimeSharedLibraries(new String[]{});
		
		assetApp.setConfiguration(assetsConfig);
		
		assetApp.setOutput(new File(outputPath.toString() + "/" + id + "/assets.swf"));
		
		assetApp.setLogger(new PLogger());
		
		try {
			if (assetApp.build(true) <= 0)
			{
				throw new BuildException("Asset SWF Build Failed.");
			}
		} catch (IOException e) {
			throw new BuildException("Error during Potomac build (assets).", e);
		}

		System.out.println("assets.swf built");
		
		verbose = false;//reset static var (if we don't reset it then it may stay true for the next task which doesn't have verbose set at all
	}
	
	private void recursiveAddComponent(File srcPath,Library bundleLib)
	{
		for (File file : srcPath.listFiles())
		{
			if (file.isHidden())
				continue;
			
			if (file.isDirectory())
			{
				recursiveAddComponent(file, bundleLib);
			}
			else
			{
				if (file.getName().toLowerCase().endsWith(".mxml") || file.getName().toLowerCase().endsWith(".as"))
					bundleLib.addComponent(file);
			}	
		}
	}
	
	private void configureConfiguration(Configuration config)
	{
		if (loadConfig == null)
		{
			config.setConfiguration(new File(sdkPath.toString() + "/frameworks/flex-config.xml"));
		}
		else
		{
			config.setConfiguration(new File(loadConfig.getPath().toString()));
		}
		
		
		config.enableDebugging(debug,"");
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
		
		for (ExternalLibraryPath ep : extPaths)
		{
			config.addExternalLibraryPath(new File[]{new File(ep.getPath().toString())});
		}
		
		File bundlexml = new File(workspacePath.toString() + "/" + id + "/bundle.xml");
		if (!bundlexml.exists())
			throw new BuildException("Could not find bundle.xml in '" + id + "'.");
		
		BundleModel bundleModel = getModel(id);

		for (String dependency : bundleModel.dependencies)
		{
			String outputBundleSWC = outputPath.toString() + "/"+ dependency + "/" +dependency + ".swc";
			String targetPlatSWC = targetPlatformPath.toString() + "/"+ dependency + "/" +dependency + ".swc";
			if (new File(outputBundleSWC).exists())
			{
				if (verbose)
					System.out.println("Adding dependency: " + outputBundleSWC);
				config.addExternalLibraryPath(new File[]{new File(outputBundleSWC)});
			}
			else if (new File(targetPlatSWC).exists())
			{
				if (verbose)
					System.out.println("Adding dependency: " + targetPlatSWC);
				config.addExternalLibraryPath(new File[]{new File(targetPlatSWC)});
			}
			else
			{
				throw new BuildException("Unable to find SWC for '" + dependency + "' in either POTOMAC_BUILD_OUTPUT or POTOMAC_TARGET_PLATFORM.");
			}
		}
		
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
		
		if (name.equals("external-library-path"))
		{
			ExternalLibraryPath ep = new ExternalLibraryPath(getProject());
			extPaths.add(ep);
			return ep;
		}
		
		if (name.equals("load-config"))
		{
			LoadConfig lc = new LoadConfig(getProject());
			loadConfig = lc;
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
