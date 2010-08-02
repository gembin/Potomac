/*******************************************************************************
 *  Copyright (c) 2009 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package com.elementriver.potomac.sdk.bundles;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IPathVariableManager;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceDelta;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.codemodel.definitions.ASDefinitionFilter;
import com.adobe.flexbuilder.codemodel.definitions.IArgument;
import com.adobe.flexbuilder.codemodel.definitions.IClass;
import com.adobe.flexbuilder.codemodel.definitions.IDefinition;
import com.adobe.flexbuilder.codemodel.definitions.IFunction;
import com.adobe.flexbuilder.codemodel.definitions.IInterface;
import com.adobe.flexbuilder.codemodel.definitions.IType;
import com.adobe.flexbuilder.codemodel.definitions.IVariable;
import com.adobe.flexbuilder.codemodel.definitions.metadata.IMetaTag;
import com.adobe.flexbuilder.codemodel.indices.IClassNameIndex;
import com.adobe.flexbuilder.codemodel.indices.IInterfaceNameIndex;
import com.adobe.flexbuilder.codemodel.internal.project.SWCFileSpecification;
import com.adobe.flexbuilder.codemodel.internal.resourcehandlers.SWCFileHandler;
import com.adobe.flexbuilder.codemodel.internal.testing.IAdaptableNode;
import com.adobe.flexbuilder.codemodel.internal.tree.AccessorNode;
import com.adobe.flexbuilder.codemodel.internal.tree.ClassNode;
import com.adobe.flexbuilder.codemodel.internal.tree.NodeBase;
import com.adobe.flexbuilder.codemodel.internal.tree.SWCFileNode;
import com.adobe.flexbuilder.codemodel.internal.tree.metadata.MetaTagNode;
import com.adobe.flexbuilder.codemodel.internal.tree.metadata.MetaTagsNode;
import com.adobe.flexbuilder.codemodel.internal.tree.mxml.BindableVariableNode;
import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.compiler.Problem;
import com.adobe.flexbuilder.project.compiler.StyleProblem;
import com.adobe.flexbuilder.project.internal.FlexLibraryProjectSettings;
import com.elementriver.potomac.sdk.Activator;
import com.elementriver.potomac.sdk.ExtensionAndPointsUtil;
import com.elementriver.potomac.sdk.IgnoredMetadata;
import com.elementriver.potomac.sdk.Potomac;

import flex2.tools.oem.Application;
import flex2.tools.oem.Configuration;
import flex2.tools.oem.Message;
import flex2.tools.oem.VirtualLocalFile;
import flex2.tools.oem.VirtualLocalFileSystem;

public class PotomacBundleBuilder extends IncrementalProjectBuilder {

	public static final String BUILDER_ID = "com.elementriver.potomac.sdk.potomacBundleBuilder";

	public static final String MARKER_TYPE = "com.elementriver.potomac.sdk.potomacProblem";
	
	private static final String ASSETS_SWF = "assets.swf";
	
	private static final String EXTENSION_META = "Extension";
	private static final String EXTENSIONPOINT_META = "ExtensionPoint";
	
	private ArrayList<HashMap<String,String>> extensions = new ArrayList<HashMap<String,String>>();
	private ArrayList<HashMap<String,String>> extensionPoints = new ArrayList<HashMap<String,String>>();
	
	private ArrayList<String> extensionAssets = new ArrayList<String>();
	
	private long startTime;
	private long metadataTotal;
	private long SWFtotal;
	private long assetTotal;
	
	public PotomacBundleBuilder()
	{
		super();
	}

	private void addMarker(IResource resource, String message, int charStart, int charEnd, 
			int severity) {
		try {
			Potomac.log("Creating marker ("+resource.getName() + "-"+message+")");
			IMarker marker = resource.createMarker(MARKER_TYPE);
			marker.setAttribute(IMarker.MESSAGE, message);
			marker.setAttribute(IMarker.SEVERITY, severity);
			marker.setAttribute(IMarker.CHAR_START, charStart);
			marker.setAttribute(IMarker.CHAR_END,charEnd + 1);
			Potomac.log("Marker created");
		} catch (CoreException e) {
			e.printStackTrace();
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.eclipse.core.internal.events.InternalBuilder#build(int,
	 *      java.util.Map, org.eclipse.core.runtime.IProgressMonitor)
	 */
	protected IProject[] build(int kind, Map args, IProgressMonitor monitor)
			throws CoreException {	
		//System.out.println("BundleBuild for " + getProject().getName());
		startTime = System.currentTimeMillis();
		
		getProject().deleteMarkers(MARKER_TYPE, false, IResource.DEPTH_ZERO);
		
		if (!getProject().getFile("bundle.xml").exists())
		{
			IMarker marker = getProject().createMarker(MARKER_TYPE);
			marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
			marker.setAttribute(IMarker.MESSAGE, "Bundle must have a bundle.xml in the root.");
		}
		else
		{
			if (kind == FULL_BUILD || kind == CLEAN_BUILD)
			{
				potomacBuild(monitor,true,true);	
			}
			else
			{
				boolean doBuild = false;
				boolean refreshBundleXMLModel = false;
				IResourceDelta delta = getDelta(getProject());
				if (delta != null)
				{
					if (delta.findMember(new Path("bundle.xml")) != null || 
							delta.findMember(new Path(".actionScriptProperties")) != null || 
							delta.findMember(new Path(".flexLibProperties")) != null ||
							delta.findMember(new Path(Potomac.getSourceDirectory(getProject()))) != null)
					{
						doBuild = true;
					}
					
					refreshBundleXMLModel = (delta.findMember(new Path("bundle.xml")) != null);
					
					
				}
				
				
//				if (!doBuild) //check referenced projs
//				{
//					IProject referencedProjs[] = getProject().getReferencedProjects();
//					for (IProject refProj : referencedProjs)
//					{
//						delta = getDelta(refProj);
//						{
//							if (delta == null)
//								continue;
//							
//							if (delta.findMember(new Path(Potomac.getOutputDirectory(refProj) + "/" + refProj.getName()+ ".swc")) != null)
//							{
//								doBuild = true;
//								break;
//							}
//						}
//					}
//				}				
				if (doBuild)
					potomacBuild(monitor,refreshBundleXMLModel,false);
			}		
		}
		
//		if (kind == FULL_BUILD) {
//			fullBuild(monitor);
//		} else {
//			IResourceDelta delta = getDelta(getProject());
//			if (delta == null) {
//				fullBuild(monitor);
//			} else {
//				incrementalBuild(delta, monitor);
//			}
//		}
		
		long millis = System.currentTimeMillis() - startTime;
		String type = "Incremental";
		if (kind == FULL_BUILD)
			type = "Full";
		if (kind == CLEAN_BUILD)
			type = "Clean";
		Potomac.log("["+getProject().getName()+"] Build Complete, Type: "+type+", total time: "+millis + " (" + ((double)millis/1000) + " seconds), " +
				"metadata time: "+metadataTotal + " (" + ((double)metadataTotal/1000) + " seconds), " +
						"SWF time: " + SWFtotal + " (" + ((double)SWFtotal/1000) + " seconds), " +
						"Asset SWF time: " + assetTotal + " (" + ((double)assetTotal/1000) + " seconds), java heap: " + (Runtime.getRuntime().totalMemory()-Runtime.getRuntime().freeMemory())/(1024*1024) + " MB");
		//System.out.println(getProject().getName() + " build took " + millis);
		return getProject().getReferencedProjects();
	}


	protected void potomacBuild(final IProgressMonitor monitor, boolean refreshBundleXMLModel,boolean cleanBuild)
			throws CoreException {
		
		//System.out.println("bundle full build " + getProject().getName());
		
		Potomac.log("["+getProject().getName()+"] Deleting markers");
		getProject().deleteMarkers(MARKER_TYPE, false, IResource.DEPTH_INFINITE);
		Potomac.log("["+getProject().getName()+"] Markers deleted");
		
		extensions.clear();
		extensionPoints.clear();
		extensionAssets.clear();
		
		monitor.beginTask("Metadata Processing", IProgressMonitor.UNKNOWN);
		long start = System.currentTimeMillis();
		doMetadataProcessing();
		metadataTotal = System.currentTimeMillis() - start;
		
		//System.out.println("done metadata");
		
		if (refreshBundleXMLModel)
			BundleModelManager.getInstance().clearModelCache(getProject().getName());
		
		BundleModel bundleModel = BundleModelManager.getInstance().getModel(getProject().getName());
		
		
		if (!bundleModel.dirty)
		{
			if (compareLists(bundleModel.extensionPoints, extensionPoints) == false ||
					compareLists(bundleModel.extensions, extensions) == false)
			{
				bundleModel.dirty = true;
			}
		}
	
		
		bundleModel.extensionPoints.clear();
		bundleModel.extensionPoints.addAll(extensionPoints);

		bundleModel.extensions.clear();
		bundleModel.extensions.addAll(extensions);
		
		IFile binBundleXML = getProject().getFile(Potomac.getOutputDirectory(getProject())+"/bundle.xml");
		
		if (bundleModel.dirty || !binBundleXML.exists())
		{
			monitor.beginTask("Writing bundle.xml to /bin", IProgressMonitor.UNKNOWN);
			
			BundleModelManager.getInstance().saveModel(getProject().getName(),true);
			BundleModelManager.getInstance().fireBundleExtensionChangeEvent(getProject().getName());
		}
		
		//This following 4 lines is just a temporary thing that will delete the ext and ext pt data from the 
		//root bundle.xml if that data exists.  The new approach does not save the data there.  That data won't
		//do any harm but its best to clean it up to remove confusion.  This code should eventually be removed
		//as there wont be anymore users who have this older data.
		if (cleanBuild && BundleModelManager.getInstance().modelHasOlderData(getProject().getName()))
		{
			//rewrite bundle.xml w/o ext data
			BundleModelManager.getInstance().saveModel(getProject().getName(),false);	
		}
		
		

		
		monitor.beginTask("Copying resources to output location", IProgressMonitor.UNKNOWN);
		
		
		//copy assets
		IFolder assets = getProject().getFolder("extensionAssets");
		if (assets.exists())
		{
			IPath toPath = new Path(Potomac.getOutputDirectory(getProject()) + "/assets");
			if (getProject().getFolder(toPath).exists())
			{
				getProject().getFolder(toPath).setReadOnly(false);
				Potomac.setAllWritable(getProject().getFolder(toPath));
				getProject().getFolder(toPath).delete(true,null);
			}
			assets.copy(toPath, IResource.FORCE | IResource.DERIVED, null);
			IResource kids[] = getProject().getFolder(toPath).members(IFolder.INCLUDE_HIDDEN);
			for (IResource kid : kids)
			{
				if (kid.isHidden() || kid.getName().startsWith("."))
					kid.delete(true,null);
			}
		}
		
		
		
		boolean doSWF = true;
		
		if (getProject().findMaxProblemSeverity(Problem.FLEX_COMPILER_PROBLEM_MARKER, true, IResource.DEPTH_INFINITE) == IMarker.SEVERITY_ERROR ||
				getProject().findMaxProblemSeverity(StyleProblem.STYLE_PROBLEM_MARKER, true, IResource.DEPTH_INFINITE) == IMarker.SEVERITY_ERROR	)
		{
			//if there are any compilation problems - don't try to create the swf
			doSWF = false;
		}
		
		if (doSWF)
		{
			
		
			
			monitor.beginTask("Building Bundle SWF",IProgressMonitor.UNKNOWN);
			
			IFolder bin = getProject().getFolder(Potomac.getOutputDirectory(getProject()));
			IFile swf = bin.getFile(getProject().getName() + ".swf");
			if (swf.exists())
			{
				swf.setReadOnly(false);
				swf.delete(true,null);
			}
			
			Application flexCompiler = null;
		
			try
			{
				flexCompiler = getCompiler();	
			} catch (IOException e) {
				throw Potomac.createCoreException("Error during Potomac build.", e);
			}	
	
			Configuration config = flexCompiler.getConfiguration();
			
		
			if (!CMFactory.getRegistrar().isProjectRegistered(getProject()))
			{
				monitor.subTask("Registering Flex Project");
				CMFactory.getRegistrar().registerProject(getProject(),null);
			}
			
			synchronized (CMFactory.getLockObject())
			{
		
				
				monitor.subTask("");
				IActionScriptProject proj = ActionScriptCore.getProject(getProject());				
				FlexLibraryProjectSettings settings = ( FlexLibraryProjectSettings ) proj.getProjectSettings();
				
				config.enableAccessibility(settings.isGenerateAccessibleSWF());
				
				IPathVariableManager pathVars = getProject().getWorkspace().getPathVariableManager();
				
				config.setExternalLibraryPath(new File[]{});
				config.setLibraryPath(new File[]{});
				config.setRuntimeSharedLibraries(new String[]{});
				config.setRuntimeSharedLibraryPath("", new String[]{}, new String[]{});
				
				IClassPathEntry paths[] = settings.computeCompilerLibraryPath();
				for (IClassPathEntry path : paths)
				{
					if (path.getKind() != IClassPathEntry.KIND_PATH)
					{
						IPath p = path.getLinkablePath();
						p = pathVars.resolvePath(p);
						
						if (path.getLinkType() == IClassPathEntry.LINK_TYPE_DEFAULT || path.getLinkType() == IClassPathEntry.LINK_TYPE_INTERNAL)
						{
							config.addLibraryPath(new File[]{p.toFile()});
						}
						else
						{
							config.addExternalLibraryPath(new File[]{p.toFile()});
						}
					}
					else
					{
						IPath p = path.getLinkablePath();
						p = pathVars.resolvePath(p);
						config.addLibraryPath(new File[]{p.toFile()});
					}
				}
				
				if (settings.isIncludeAllClasses())
				{
					IFolder src = getProject().getFolder(ActionScriptCore.getProject(getProject()).getProjectSettings().getMainSourceFolder().toString());
					ArrayList<IClass> types = Potomac.getAllClassesInFolder(src,null);
					ArrayList<String> clzes = new ArrayList<String>();
					for (IClass clz : types)
					{
						clzes.add(clz.getQualifiedName());
					}
					config.setIncludes(clzes.toArray(new String[]{}));
				}
				else
				{
					String classes[] = settings.getIncludeClasses();
					config.setIncludes(classes);
				}				
			}
			
			try {
		
				int totalProblems = getProject().findMarkers(Problem.FLEX_COMPILER_PROBLEM_MARKER, true, IResource.DEPTH_INFINITE).length;
				totalProblems += getProject().findMarkers(StyleProblem.STYLE_PROBLEM_MARKER, true, IResource.DEPTH_INFINITE).length;
		
				final ArrayList<String> errors = new ArrayList<String>();
				flexCompiler.setLogger(new flex2.tools.oem.Logger() {
					public void log(Message msg, int arg1, String arg2) {
						if (msg.getLevel() == msg.ERROR)
						{
							errors.add(msg.toString());
						}
					}
				});
			    start = System.currentTimeMillis();
				if (flexCompiler.build(true) <= 0)
				{
					String message = "";
					for (String error : errors)
					{
						message += error + "\r\n";
					}
					addMarker(getProject(), "Potomac encountered an expected error during build:  " + message, 0, 0, IMarker.SEVERITY_ERROR);
				}
		
				SWFtotal = System.currentTimeMillis() - start;
				
			} catch (IOException e) {
				throw Potomac.createCoreException("Error during Flex portion of Potomac build.", e);
			}
		}
		
		boolean doAssetSWF = cleanBuild || bundleModel.dirty;
		if (!doAssetSWF)
		{
			//check to see if any of the assets changed
			IResourceDelta delta = getDelta(getProject());
			if (delta != null)
			{
				for (String assetPath : extensionAssets)
				{
					if (delta.findMember(new Path(assetPath)) != null)
					{
						doAssetSWF = true;
						break;
					}
				}
			}
			
			//check to see if the list of assets changed
			if (!doAssetSWF)
			{
				if (bundleModel.extensionAssets.size() != extensionAssets.size())
				{
					doAssetSWF = true;
				}
				else
				{
					ArrayList<String> assetsCopy= new ArrayList<String>(extensionAssets);
					for (String asset : bundleModel.extensionAssets)
					{
						if (assetsCopy.contains(asset))
							assetsCopy.remove(asset);
					}
					
					doAssetSWF = (assetsCopy.size() != 0);
				}
			}
		}
		
		//save the update-to-date list of assets to cache in the bundle model
		bundleModel.extensionAssets = extensionAssets;
		
		if (doAssetSWF)
		{
			
			IFolder bin = getProject().getFolder(Potomac.getOutputDirectory(getProject()));
			IFile swf = bin.getFile(ASSETS_SWF);
			if (swf.exists())
			{
				swf.setReadOnly(false);
				swf.delete(true,null);
			}
			
			String className = "PotomacAssets_"+getProject().getName();
			
			String assetsClass = "package{ import flash.display.Sprite; public class " + className + " extends Sprite {";
			
			String newLine = System.getProperty("line.separator");
			
			assetsClass += newLine + newLine;
			
			String path = getProject().getFile(Potomac.getOutputDirectory(getProject())+"/bundle.xml").getLocation().makeAbsolute().toFile().getAbsolutePath();
			
			path = path.replace('\\','/');
			assetsClass += "[Embed(source=\""+path+"\",mimeType=\"application/octet-stream\")]" +newLine;;
			
			String varName = "bundlexml";
			
			assetsClass += "public var "+varName+":Class;";
			
			assetsClass += newLine + newLine;
			
			for (String asset : extensionAssets)
			{
				path = getProject().getFile(asset).getLocation().makeAbsolute().toFile().getAbsolutePath();
				
				path = path.replace('\\','/');
				assetsClass += "[Embed(source=\""+path+"\")]" +newLine;;
				
				varName = asset;
				varName = varName.replace('/','_');
				varName = varName.replace('.','_');
				varName = varName.replace(' ','_');
				
				assetsClass += "public var "+varName+":Class;";
				
				assetsClass += newLine + newLine;
			}
			
			assetsClass += newLine + newLine;
			
			assetsClass += "}}";

			VirtualLocalFile assetsVF;
			try {
				File sourceDir = getProject().getFile(Potomac.getSourceDirectory(getProject())).getLocation().toFile().getCanonicalFile();
				
				
				VirtualLocalFileSystem fs = new VirtualLocalFileSystem();
				assetsVF = fs.create(new File(sourceDir, className + ".as").getCanonicalPath(), assetsClass, sourceDir, System.currentTimeMillis());
			} catch (IOException e) {
				throw Potomac.createCoreException("Error during Potomac build (assets).", e);
			}

			
			Application assetApp = new Application(assetsVF);
			Configuration config = assetApp.getDefaultConfiguration();
			
			IActionScriptProject proj = ActionScriptCore.getProject(getProject());				
			FlexLibraryProjectSettings settings = ( FlexLibraryProjectSettings ) proj.getProjectSettings();

			File configFile = settings.getFlexSDK().getFlexConfigFile();
			config.setConfiguration(configFile);
			
			config.setLibraryPath(new File[]{});
			config.addExternalLibraryPath(new File[]{new File(settings.getFlexSDK().getFrameworksDir().getAbsolutePath() +"/libs/flex.swc")});
			//config.setLibraryPath(new File[]{new File("C:/mergedSDK/frameworks/" +"/libs/flex.swc")});
			config.setLocale(new String[]{});
			config.setRuntimeSharedLibraries(new String[]{});
			
			config.enableDebugging(true, "");
			assetApp.setConfiguration(config);
			
			try {
				assetApp.setOutput(getProject().getFile(Potomac.getOutputDirectory(getProject()) + "/"+ASSETS_SWF).getLocation().toFile().getCanonicalFile());
			} catch (IOException e) {
				throw Potomac.createCoreException("Error during Potomac build (assets).", e);
			}
			
			final ArrayList<String> errors = new ArrayList<String>();
			assetApp.setLogger(new flex2.tools.oem.Logger() {
				public void log(Message msg, int arg1, String arg2) {
					if (msg.getLevel() == msg.ERROR)
					{
						errors.add(msg.toString());
					}
				}
			});
			try {
				
				start = System.currentTimeMillis();
				if (assetApp.build(true) <= 0)
				{
					String message = "";
					for (String error : errors)
					{
						message += error + "\r\n";
					}
					addMarker(getProject(), "Potomac encountered an expected error during assets build:  " + message, 0, 0, IMarker.SEVERITY_ERROR);
				}
				assetTotal = System.currentTimeMillis() - start;
				
			} catch (IOException e) {
				throw Potomac.createCoreException("Error during Potomac build (assets).", e);
			}
		}
		
		getProject().getFolder(Potomac.getOutputDirectory(getProject())).refreshLocal(IResource.DEPTH_INFINITE, null);
		bundleModel.dirty = false;
	}
	
	private Application getCompiler() throws IOException
	{
		VirtualLocalFileSystem fs = new VirtualLocalFileSystem();

		File sourceDir = getProject().getFile(Potomac.getSourceDirectory(getProject())).getLocation().toFile().getCanonicalFile();
		
		String moduleName = getProject().getName() + "PotomacModule";
		
		//http://bugs.adobe.com/jira/browse/SDK-17801
		//fixed in flex4
//		String moduleClass = "package {";
//		moduleClass += "	import mx.modules.ModuleBase;";
//		moduleClass += "	public class "+moduleName+" extends ModuleBase{";
//		moduleClass += "	public function "+moduleName+"(){";
//		moduleClass += "			super();";
//		moduleClass += "		}";
//		moduleClass += "	}";
//		moduleClass += "}";
		
		String moduleClass = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
								"<mx:Module xmlns:mx=\"http://www.adobe.com/2006/mxml\" layout=\"absolute\" width=\"100\" height=\"100\">" +
								"</mx:Module>";

		VirtualLocalFile moduleFile = fs.create(new File(sourceDir, moduleName + ".mxml").getCanonicalPath(), moduleClass, sourceDir, System.currentTimeMillis());
		
		Application bundleApp = new Application(moduleFile);
		bundleApp.setConfiguration(bundleApp.getDefaultConfiguration());
		Configuration config = bundleApp.getConfiguration();
		
		if (!CMFactory.getRegistrar().isProjectRegistered(getProject()))
		{
			CMFactory.getRegistrar().registerProject(getProject(),null);
		}
		
		synchronized (CMFactory.getLockObject())
		{	
			IActionScriptProject proj = ActionScriptCore.getProject(getProject());				
			FlexLibraryProjectSettings settings = ( FlexLibraryProjectSettings ) proj.getProjectSettings();

			File configFile = settings.getFlexSDK().getFlexConfigFile();
			config.setConfiguration(configFile);
			
			bundleApp.setOutput(getProject().getFile(Potomac.getOutputDirectory(getProject()) + "/" + getProject().getName() + ".swf").getLocation().toFile().getCanonicalFile());
			String compilerArgs = settings.getAdditionalCompilerArgs();
			if (compilerArgs.indexOf("-locale ") != -1)
			{
				String locales = compilerArgs.substring(compilerArgs.indexOf("-locale ") + 8);
				if (locales.indexOf("-") != -1)
					locales = locales.substring(0,locales.indexOf("-"));
				
				config.setLocale(locales.split(","));
			}

			config.enableDebugging(true,"");
			config.addSourcePath(new File[]{sourceDir});
			config.keepAllTypeSelectors(true);	
			
			config.setLocalFontSnapshot(new File(settings.getFlexSDK().getFlexConfigDir(),"localFonts.ser"));
		}
			
		bundleApp.setLogger(new flex2.tools.oem.Logger() {	
			public void log(Message arg0, int arg1, String arg2) {
			}
		});
		
		return bundleApp;
	}
	
	private void doMetadataProcessing() throws CoreException
	{		
		
		if (!CMFactory.getRegistrar().isProjectRegistered(getProject()))
		{
		
			//System.out.println("regin"+getProject().getName());
			CMFactory.getRegistrar().registerProject(getProject(),null);
			//System.out.println("reged"+getProject().getName());
		}
		
		
		ArrayList<IClass> types = null;
		
		
		synchronized (CMFactory.getLockObject())
   	 	{	
			IFolder src = getProject().getFolder(ActionScriptCore.getProject(getProject()).getProjectSettings().getMainSourceFolder().toString());
			types = Potomac.getAllClassesInFolder(src,null);
   	 	}
		
		//first get all extPts	
		for (IType type : types) {
			
			IMetaTag tags[] = null;
			
			synchronized (CMFactory.getLockObject())
	   	 	{
				if (type.getMetaTags() == null)
					continue;
			
				tags = type.getMetaTags().getTagsByName((EXTENSIONPOINT_META));
	   	 	}
			
			for (IMetaTag tag : tags) {
				
				HashMap<String,String> extPt = getMapFromTag(tag);
				ArrayList<String> msgs = validateExtensionPoint(extPt);
				if (msgs.size() > 0)
				{
					for (String msg : msgs)
					{
						int codeOffsets[] = new int[2];
						getStartAndEndForTag(tag, codeOffsets);
						
						IFile file = getProject().getWorkspace().getRoot().getFileForLocation(new Path(type.getContainingSourceFilePath()));
						addMarker(file, msg, codeOffsets[0],codeOffsets[1], IMarker.SEVERITY_ERROR);							
					}
				}
				else
				{
					if (!extPt.get("id").contains("_") && !getProject().getName().contains("potomac"))
					{
						String msg = "Custom extension points should be prefaced with an unique string and underscore (ex 'MyApp_Point').  This prevents metadata tag collision.";
						
						int codeOffsets[] = new int[2];
						getStartAndEndForTag(tag, codeOffsets);
						
						IFile file = getProject().getWorkspace().getRoot().getFileForLocation(new Path(type.getContainingSourceFilePath()));
						addMarker(file, msg, codeOffsets[0],codeOffsets[1], IMarker.SEVERITY_WARNING);
					}
					
					int codeOffsets[] = new int[2];
					getStartAndEndForTag(tag, codeOffsets);
					extPt.put("codeStart",codeOffsets[0] + "");
					extPt.put("codeEnd",codeOffsets[1] + "");
					
					extPt.put("bundle",getProject().getName());
					extPt.put("declaredBy",type.getQualifiedName());
					extensionPoints.add(extPt);
				}
			}
		}
		
		
		BundleModel model = BundleModelManager.getInstance().getModel(getProject().getName());			
		
		ArrayList<String> allExtPts = BundleModelManager.getInstance().getAllExtensionPointIDs(model.dependencies);
		//now add the extPts we just got
		for (HashMap<String,String> pt : extensionPoints)
		{
			allExtPts.add(pt.get("id"));
		}
		
		//now get all metadata tags and see if they're extensions
		for (IClass type : types) 
		{				
			
			ArrayList<IMetaTag> tags = getAllMetaTagsInType(type);
			
		
			for (IMetaTag tag : tags) {
				String tagName = tag.getTagName();
				
				
				if (allExtPts.contains(tagName) || tagName.equals(EXTENSION_META))
				{	
					
					HashMap<String,String> ext = getMapFromTag(tag);
					
					String point = "";
					if (tagName.equals(EXTENSION_META))
					{
						point = ext.get("point");
					}
					else
					{
						point = tagName;
						ext.put("point",tagName);
					}
					HashMap<String,String> extPt = null;
					for (HashMap extPtIter : extensionPoints)
					{
						if (extPtIter.get("id").equals(point))
						{
							extPt = extPtIter;
							break;
						}
					}
					if (extPt == null)
					{
						extPt = BundleModelManager.getInstance().getExtensionPoint(point);
						
						//ensure we don't pull an older version from the extPt cache.  This can
						//happen if we pull the extPt from the cache for this bundle.  If the 
						//extPt was valid it would have been found in the extensionPoints variable
						//above
						if (extPt.get("bundle").equals(getProject().getName()))
						{
							extPt = null;
						}
					}		
					
					ArrayList<String> msgs = null;
					if (extPt == null)
					{
						msgs = new ArrayList<String>();
						msgs.add("Extension point '" + point + "' isn't valid.");
					}
					else if (type instanceof IInterface)
					{
						msgs = new ArrayList<String>();
						msgs.add("Cannot declare extensions on interfaces.");
					}
					else
					{
						msgs = validateExtension(ext,extPt,type,tag);
					}						
					
					if (msgs.size() > 0)
					{
						IFile file = getProject().getWorkspace().getRoot().getFileForLocation(new Path(type.getContainingSourceFilePath()));
						for (String msg : msgs)
						{							
							int codeOffsets[] = new int[2];
							getStartAndEndForTag(tag, codeOffsets);
							
							addMarker(file, msg, codeOffsets[0],codeOffsets[1],IMarker.SEVERITY_ERROR);							
						}
					}
					else
					{
						IDefinition def = getDeclaringDefinition(tag);
						if (def instanceof IFunction && !(def instanceof BindableVariableNode))
						{								
							ext.put("function",def.getName());
							ext.put("functionSignature",getFunctionString((IFunction) def));
						}
						else if (def instanceof IVariable)
						{
							ext.put("variable",def.getName());
							String varTypeName = resolveVarType((IVariable) def);
							if (varTypeName == null)
							{
								varTypeName = "ERROR";
								IMarker marker = getProject().createMarker(MARKER_TYPE);
								marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
								marker.setAttribute(IMarker.MESSAGE,"The Flex Code Model is unable to resolve the type for variable:" + def +".  This is an intermittent problem that usually occurs when cleaning the entire workspace.  Cleaning or building this individual project should resolve it.");					
							}
							ext.put("variableType",varTypeName);
						}
											
						int codeOffsets[] = new int[2];
						getStartAndEndForTag(tag, codeOffsets);
						ext.put("codeStart",codeOffsets[0] + "");
						ext.put("codeEnd",codeOffsets[1] + "");
						
						ext.put("bundle",getProject().getName());
						ext.put("class",type.getQualifiedName());						
						extensions.add(ext);
					}
				}
				else
				{
					//check to see if we should add a warning that this is an unknown meta tag
					if (tagName.equals(EXTENSIONPOINT_META))
					{
						if (!(getDeclaringDefinition(tag) instanceof IType))
						{
							int codeOffsets[] = new int[2];
							getStartAndEndForTag(tag, codeOffsets);
							
							IFile file = getProject().getWorkspace().getRoot().getFileForLocation(new Path(type.getContainingSourceFilePath()));
							addMarker(file, "ExtensionPoints must be defined on classes.", codeOffsets[0],codeOffsets[1],IMarker.SEVERITY_ERROR);
						}
					} else if (!IgnoredMetadata.isIgnored(tagName) && !IgnoredMetadata.isSourceMateValidating(getProject()))
					{
						int codeOffsets[] = new int[2];
						getStartAndEndForTag(tag, codeOffsets);
						
						
						IFile file = getProject().getWorkspace().getRoot().getFileForLocation(new Path(type.getContainingSourceFilePath()));
						addMarker(file, "Unknown Metadata Tag: " + tag.getTagName(), codeOffsets[0],codeOffsets[1],IMarker.SEVERITY_WARNING);
					}
				}
			}
		}
	}
	
	private ArrayList<String> validateExtension(HashMap<String,String> ext, HashMap<String,String> extPt,IType containingType,IMetaTag tag)
	{
		ArrayList<String> msgs = new ArrayList<String>();
	

		for (String key : extPt.keySet()) 
		{					
			if (key.equals("bundle") || key.equals("declaredBy") || key.equals("id") ||
					key.equals("type") || key.equals("declaredOn") || key.equals("access") )
			{
				continue;
			}

			String datatype = extPt.get(key);
			boolean reqd = datatype.startsWith("*");
			if (reqd)
				datatype = datatype.substring(1);
			
			String value = ext.get(key);
			
			if (value != null && !value.trim().equals(""))
			{
				
				//check datatypes
				if (datatype.equalsIgnoreCase("integer"))
				{
					try {
						Integer.parseInt(value);
					} catch (NumberFormatException e) {
						msgs.add("Attribute '" + key + "' must be a valid integer.");
					}
				}
				else if (datatype.equalsIgnoreCase("boolean"))
				{
					if (!value.equalsIgnoreCase("true") && !value.equalsIgnoreCase("false"))
					{
						msgs.add("Attribute '" + key + "' must be either true or false.");
					}
				}
				else if (datatype.toLowerCase().startsWith("class"))
				{
					String classType = "";
					if (datatype.length() > 6)
						classType = datatype.substring(6);
					
					IDefinition def = getFlexDefinition(value);
					if (def == null || !(def instanceof IClass))
					{
						msgs.add("Attribute + '" + key + "' must be a fully qualified class name.");
					}
					else
					{
						IClass valueDef = (IClass) getFlexDefinition(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("interface"))
				{
					String classType = "";
					if (datatype.length() > 10)
						classType = datatype.substring(10);
					
					IDefinition def = getFlexDefinition(value);
					if (def == null || !(def instanceof IInterface))
					{
						msgs.add("Attribute + '" + key + "' must be a fully qualified interface name.");
					}
					else
					{
						IInterface valueDef = (IInterface) getFlexDefinition(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("type"))
				{
					String classType = "";
					if (datatype.length() > 5)
						classType = datatype.substring(5);
					
					IDefinition def = getFlexDefinition(value);
					if (def == null || !(def instanceof IType))
					{
						msgs.add("Attribute '" + key + "' must be a fully qualified type name.");
					}
					else
					{
						IType valueDef = (IType) getFlexDefinition(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("choice"))
				{
					String choicesString = "";
					if (datatype.length() > 7)
						choicesString = datatype.substring(7);
					
					String choices[] = choicesString.split(",");
					boolean found = false;
					for (String choice : choices)
					{
						if (choice.equals(value))
						{
							found = true;
							break;
						}
					}
					if (!found)
					{
						msgs.add("Attribute '" + key + "' must be one of the following values :" + choicesString);
					}
				}
				else if (datatype.startsWith("asset"))
				{
					boolean addToAssetSWF = true;
					
					IFile asset = getProject().getFile(value);					
					if (!asset.exists())
					{
						asset = getProject().getFile("extensionAssets/" + value);
						if (asset.exists())
						{
							ext.put(key,"extensionAssets/" + value);
						}
					}
					
					if (!asset.exists())
					{
						msgs.add("Asset '" + value + "' not found.");
						addToAssetSWF = false;
					}
					
					String assetTypes = "";
					if (datatype.length() > 6)
						assetTypes = datatype.substring(6);
					
					String types[] = assetTypes.split(",");
					boolean found = false;
					for (String type : types)
					{
						if (value.toLowerCase().endsWith("." + type))
						{
							found = true;
							break;
						}
					}
					if (!found)
					{
						msgs.add("Attribute '" + key + "' must be an asset of type: " + assetTypes);
						addToAssetSWF = false;
					}
					
					if (addToAssetSWF)
					{
						if (!extensionAssets.contains(asset.getProjectRelativePath().toString()))
							extensionAssets.add(asset.getProjectRelativePath().toString());
					}
				}
			}
			else if (reqd)
			{
				msgs.add("Missing required attribute '" + key + "'.");
			}					
		}
		
		
		//Setup the data necessary to check attrib names when argumentsAsAttributes is true
		ArrayList<IVariable> vars = new ArrayList<IVariable>();
		String argsAsAttribsVal = extPt.get("argumentsAsAttributes");
		boolean argsAsAttribs = (argsAsAttribsVal != null && argsAsAttribsVal.equalsIgnoreCase("true"));
		if (argsAsAttribs)
		{
			IDefinition def = getDeclaringDefinition(tag);
			if (def instanceof IFunction)
			{
				vars.addAll(Arrays.asList(((IFunction)def).getArguments()));
			}
			else if (def instanceof IVariable)
			{
				vars.add((IVariable) def);
			}
			else
			{
				argsAsAttribs = false;
			}				
		}
				
		//look for extra attribs
		for (String key : ext.keySet()){
			if (key.equals("point") || key.equals("enablesFor")) {
				continue;
			}
			
			if (!ExtensionAndPointsUtil.isValidExtensionAttribute(key))
			{
				msgs.add("Attribute '" + key + "' is not a valid attribute name.");
				continue;
			}
			
			if (!extPt.containsKey(key))
			{
				if (argsAsAttribs)
				{
					boolean foundName = false;
					//check that attrib is an arg name				
					for (IVariable var : vars)
					{
						if (var.getName().equals(key))
						{
							foundName = true;
							break;
						}
					}	
					if (!foundName)
					{
						msgs.add("Invalid attribute '" + key + "'.");
					}
				}
				else					
				{
					msgs.add("Invalid attribute '" + key + "'.");
				}
			}
		}
		
		//check special type requirements
		if (extPt.containsKey("type"))
		{
			String type = extPt.get("type");
			if (type.startsWith("*"))
				type = type.substring(1);
			
			boolean isInstance = false;
			
			if (!containingType.isInstanceOf(type))
			{
				//temporary fix - same prob as resolveVarType stuff - FB has
				//some sort of bug that sometimes not all dependency class are
				//in the builder class path
				if (containingType instanceof ClassNode)
				{
					ClassNode clzNode = (ClassNode)containingType;
					
					String baseClass = clzNode.getBaseClassName();
					
					if (baseClass.equals(type))
					{
						isInstance = true;
					}
					else
					{
						Collection<String> imports = new ArrayList<String>();					
						clzNode.getScope().getAllImports(imports);
						for (String imp : imports)
						{
							if (imp.endsWith("." + baseClass) && imp.equals(type))
							{
								isInstance = true;
								break;
							}
						}
					}
				}	
			}
			else
			{
				isInstance = true;
			}
			
			if (!isInstance)
				msgs.add("This tag must be declared on classes that extend " + type + ".");
		}
		
		//check special access requirements
		if (extPt.containsKey("access"))
		{
			String accessTypes = extPt.get("access");
			if (accessTypes.startsWith("*"))
				accessTypes = accessTypes.substring(1);
			
			IDefinition declarer = getDeclaringDefinition(tag);
			String access = declarer.getNamespace();
			if (!accessTypes.contains(access))
			{
				msgs.add("This tag must be declared on definitions with one of the following access modifiers: " + accessTypes +".");
			}
		}
				
		//check special declaredOn requirements
		if (extPt.containsKey("declaredOn"))
		{
			String declaredOn = extPt.get("declaredOn");
			if (declaredOn.startsWith("*"))
			{
				declaredOn = declaredOn.substring(1);
			}
			IDefinition declarer = getDeclaringDefinition(tag);
			String classification = "";
			if (declarer instanceof IFunction)
			{
				if (((IFunction)declarer).isConstructor())
				{
					classification = "constructors";
				}
				else
				{
					classification = "methods";
				}
			} else if (declarer instanceof IClass)
			{
				classification = "classes";
			} else if (declarer instanceof IVariable)
			{
				classification = "variables";
			}

			if (!declaredOn.contains(classification))
			{
				msgs.add("This tag must be declared on one of the following: " + declaredOn +".");
			}			
		}
		
		if (extPt.containsKey("idRequired"))
		{
			if (extPt.get("idRequired").equals("true"))
			{
				if (!ext.containsKey("id"))
				{
					msgs.add("Missing required attribute 'id'.");
				}
			}
		}

		return msgs;
	}
	
	private ArrayList<String> validateExtensionPoint(HashMap<String,String> attribs)
	{
		ArrayList<String> msgs = new ArrayList<String>();
		
		String id = (String) attribs.get("id");
		if (id == null || id.equals(""))
		{
			msgs.add("ExtensionPoint 'id' parameter not found.");
		}
		else
		{
			if (!ExtensionAndPointsUtil.isValidExtensionPointID(id))
			{
				msgs.add("ID '" + attribs.get(id) +"' is not a valid extension point id.");
			}
		}
		

		for(String key : attribs.keySet()) {     		
			
			if (ExtensionAndPointsUtil.isSpecialExtensionPointAttributes(key))
				continue;
			
			if (ExtensionAndPointsUtil.isReservedExtensionPointAttribute(key))
			{
				msgs.add("Attribute '" + key + "' is a reserved attribute name.");
				continue;
			}
			
			if (key.equals("rslRequired"))
			{
				msgs.add("The rslRequired attribute has been replaced with the preloadRequired attribute.");
				continue;
			}
			
		     String value = (String) attribs.get(key);
		     
		     if (ExtensionAndPointsUtil.isAutoAddedExtensionPointAttributes(key))
		     {
		    	 msgs.add("Attribute '" + key + "' is an automatically generated attribute.");
		    	 continue;
		     }
		     
		     if (value.startsWith("*"))
    		 {
		    	 value = value.substring(1);
    		 }

		     
		     if (value != null && !value.startsWith("choice:") && !value.startsWith("type:") && 
		    		 !value.equals("type") && !value.startsWith("class:") && 
		    		 !value.equals("class") && !value.startsWith("interface:") && 
		    		 !value.equals("interface") && !value.equals("string") && 
		    		 !value.equals("integer") && !value.equals("boolean") &&
		    		 !value.equals("asset") && !value.startsWith("asset:"))
		     {
		    	 msgs.add("Attribute '" + key + "' specifies an invalid datatype.  Valid datatypes are string, integer, boolean, type, class, interface, asset, or choice.");
		     }	
		     
		     //TODO: check we don't have an existing point with the same id
		     
		     //check any class: types are ok
		     if (value.startsWith("class:") || value.startsWith("interface:") || value.startsWith("type:"))
		     {
		    	 String className = "";
		    	 if (value.toLowerCase().startsWith("class:"))
		    	 {
		    		 className = value.substring(6);
		    	 }
		    	 else if (value.toLowerCase().startsWith("interface:"))
		    	 {
		    		 className = value.substring(10); 
		    	 }
		    	 else
		    	 {
		    		 className = value.substring(5);
		    	 }

		    	 IDefinition def = getFlexDefinition(className);
		    	 if (def == null)
		    	 {
		    		 msgs.add(className +" isn't a valid type.");
		    	 }
		    	 else 
		    	 {
		    		 boolean valid = (def instanceof IType);
		    		 if (!valid)
		    		 {
		    			 msgs.add(className + " isn't a valid type.");
		    		 }
		    		 else
		    		 {
				    	 if (value.toLowerCase().startsWith("class:") && !(def instanceof IType))
				    	 {
				    		 msgs.add(className + " isn't a valid type.");
				    	 }
				    	 else if (value.toLowerCase().startsWith("interface:") && !(def instanceof IInterface))
				    	 {
				    		msgs.add(className + " isn't a valid inteface.");
				    	 }
		    		 }
		    	 }
		     }			     
		}
		
		
		//Do type checking
		String type = attribs.get("type");
		if (type != null)
		{
		     if (type.startsWith("*"))
			 {
		    	 type = type.substring(1);
			 }

	    	 IDefinition def = getFlexDefinition(type);
	    	 if (def == null)
	    	 {
	    		 msgs.add(type +" isn't a valid type.");
	    	 }
	    	 else 
	    	 {
	    		 boolean valid = (def instanceof IType);
	    		 if (!valid)
	    		 {
	    			 msgs.add(type + " isn't a class or interface.");
	    		 }
	    	 }
	     }	

		
    	 //Do access checking
		String access = attribs.get("access");
		if (access != null)
		{
		     if (access.startsWith("*"))
			 {
		    	 access = access.substring(1);
			 }
		     String accessTypes[] = access.split(",");
		     for (String choice : accessTypes)
		     {
		    	 if (!choice.equals("private") && !choice.equals("protected") && !choice.equals("public") && !choice.equals("internal"))
		    	 {
		    		 msgs.add("Special attribute 'access' must be a comma delimited string with any of the following values: public,protected,private,internal.");
		    		 break;
		    	 }
		     }
		}
    	   	 
    	 
    	 //Do declaredOn checking
		String declaredOn = attribs.get("declaredOn");
		if (declaredOn != null)
		{
			if (declaredOn.startsWith("*"))
			{
				declaredOn = declaredOn.substring(1);
			}
		     String choices[] = declaredOn.split(",");
		     for (String choice : choices)
		     {
		    	 if (!choice.equals("classes") && !choice.equals("methods") && !choice.equals("variables") && !choice.equals("constructors"))
		    	 {
		    		 msgs.add("Special attribute 'declaredOn' must be a comma delimited string with any of the following values: classes,constructors,methods,variables.");
		    		 break;
		    	 }
		     }
		}
			
		//Do argumentsAsAttributes checking
		String argsAsAttribs = attribs.get("argumentsAsAttributes");
		if (argsAsAttribs != null)
		{
			if (argsAsAttribs.startsWith("*"))
			{
				argsAsAttribs = argsAsAttribs.substring(1);
			}
			if (argsAsAttribs.equalsIgnoreCase("true"))
			{
				if (declaredOn != null && !(declaredOn.contains("methods") || declaredOn.contains("constructors") || declaredOn.contains("variables")))
				{
					msgs.add("'argumentsAsAttributes' may only be specified when 'declaredOn' includes constructors, methods, or variables.");
				}
			}			
		}
		
		
		return msgs;
	}
	

	private HashMap<String,String> getMapFromTag(IMetaTag tag)
	{
		HashMap<String,String> map  = null;
		synchronized (CMFactory.getLockObject()) {
			
			map = new HashMap<String,String> ();
			
			
			MetaTagNode tag2 = (MetaTagNode) tag;
			IAdaptableNode attribs[] = tag2.getAdaptableChildren();
			
	
			for (int i = 0; i < attribs.length; i++) {
				String name = attribs[i].getAdaptableAttribute("name");
				String value = attribs[i].getAdaptableAttribute("value");
				map.put(name, value);
			}
		}
		
		return map;
	}
		
	private IDefinition getFlexDefinition(String className)
	{
		if (!CMFactory.getRegistrar().isProjectRegistered(getProject()))
		{
			CMFactory.getRegistrar().registerProject(getProject(),null);
		}
		
		IDefinition clazz = null;
		
		synchronized (CMFactory.getLockObject()) {
			
			IClassNameIndex index = (IClassNameIndex) CMFactory.getManager().getProjectFor(getProject()).getIndex(IClassNameIndex.ID);
			clazz = index.getByQualifiedName(className);
	
			if (clazz == null)
			{
				IInterfaceNameIndex index2 = (IInterfaceNameIndex) CMFactory.getManager().getProjectFor(getProject()).getIndex(IInterfaceNameIndex.ID);
				clazz = index2.getByQualifiedName(className);
			}
		}
		
	
		return clazz;
	}

	private ArrayList<IMetaTag> getAllMetaTagsInType(IType type)
	{
		ArrayList<IMetaTag> tags = new ArrayList<IMetaTag>();
		
		synchronized (CMFactory.getLockObject()) {
			
			if (type.getMetaTags() != null)
			{
				for (IMetaTag tag : type.getMetaTags().getAllTags())
				{
					tags.add(tag);
				}
			}
	
			IDefinition defs[] = type.getAllMembers(ASDefinitionFilter.createImmediateMemberFilter(type,ASDefinitionFilter.ClassificationValue.ALL,true));
			
			for (IDefinition def : defs)
			{
				if (def instanceof IFunction && !(def instanceof BindableVariableNode))
				{
					if (def.getMetaTags() == null)
						continue;
					
					//FB-21888 
					//Skip the tags if this is a getter/setter
					if (def instanceof AccessorNode)
						continue;
					IMetaTag defTags[] = def.getMetaTags().getAllTags();
					for (IMetaTag tag : defTags)
					{
						tags.add(tag);
					}
				}
				else if (def instanceof IVariable)
				{
					IVariable var = (IVariable) def;
					if (var.getName().equals("super") || var.getName().equals("this"))
						continue;
					
					if (def.getMetaTags() == null)
						continue;
					IMetaTag defTags[] = def.getMetaTags().getAllTags();
					for (IMetaTag tag : defTags)
					{
						tags.add(tag);
					}
				}
			}
		}

		return tags;
	}
	
	private IDefinition getDeclaringDefinition(IMetaTag tag)
	{
		synchronized (CMFactory.getLockObject()) {
	
			MetaTagNode node = (MetaTagNode) tag;
			if (((MetaTagsNode)node.getParent()).getDecoratedDefinition() != null)
				return (IDefinition) ((MetaTagsNode)node.getParent()).getDecoratedDefinition(); 
			
			return (IDefinition) ((MetaTagsNode)node.getParent()).getParent();
		}
	}
	
	private void getStartAndEndForTag(IMetaTag tag,int codeOffsets[])
	{
		int start = 0;
		int end = 0;
		synchronized (CMFactory.getLockObject()) {
			
			start = ((MetaTagNode)tag).getStart();
			end = ((MetaTagNode)tag).getEnd();
			end ++; //flex doesn't add the ]
			
			if (start == -1)
			{
				//Bug/limitation in the code model causing us grief here
				//FB-21915
				NodeBase node = (NodeBase) getDeclaringDefinition(tag);
				start = node.getStart();
				end = node.getEnd();
			}
		}
		
		codeOffsets[0] = start;
		codeOffsets[1] = end;
		
	
	}
	
	private String getFunctionString(IFunction func) throws CoreException
	{
		String funcString = "(";
		IArgument vars[] = func.getArguments();
		for (IArgument var : vars)
		{
			String argType = resolveVarType(var);
			if (argType == null)
			{
				Potomac.log("Creating marker - code model error");
				argType = "ERROR";
				IMarker marker = getProject().createMarker(MARKER_TYPE);
				marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
				marker.setAttribute(IMarker.MESSAGE,"The Flex Code Model is unable to resolve the type for variable:" + var +".  This is an intermittent problem that usually occurs when cleaning the entire workspace.  Cleaning or building this individual project should resolve it.");
				Potomac.log("Marker created");
			}
			
			funcString += var.getName() + ":" + argType;
			if (var instanceof IArgument && ((IArgument)var).getDefaultValue() != null)
			{
				//funcString += "=" + ((IArgument)var).getDefaultValue();
				//The default value may contain quotes or other characters that
				//will interfere with the xml.  So for now we're just using 'default' to
				//record the fact that the it had a default value
				funcString += "=*";
			}
			funcString += ",";
		}
		if (funcString.endsWith(","))
		{
			funcString = funcString.substring(0,funcString.length() -1);
		}
		funcString += "):";
		IType returnType = func.resolveReturnType(null);
		if (returnType == null)
		{
			funcString += "void";
		}
		else
		{
			funcString += returnType.getQualifiedName();
		}
		return funcString;
	}
	
	private String resolveVarType(IVariable var) throws CoreException
	{
				
		IType type = var.resolveVariableType(null);
		boolean isnull = false;
		if (type == null)
		{
			isnull = true;
			//There appears to be some bug in the FB code model API where resolveVarType returns null unexpectedly
			//We can track this down it appears that the project's class index does not contain all the expected/necessary classes
			//The class index sometimes seems to be missing classes.  In all our instances, the missing classes were from referenced
			//dependency bundles.  
			//The code below then looks through the referenced bundle project's individual class indexes to see if we can manually
			//resolve the var type.
			
			Collection<String> imports = new ArrayList<String>();
			IType parentType = (IType) var.getAncestorOfType(IType.class);
			
			parentType.getScope().getAllImports(imports);
			
			//instead we need to go through the classpath entries
			BundleModel model = BundleModelManager.getInstance().getModel(getProject().getName());	
			
			for (String dependency : model.dependencies)
			{
				
				IProject dependencyProject = ResourcesPlugin.getWorkspace().getRoot().getProject(dependency);
				com.adobe.flexbuilder.codemodel.project.IProject flexProject = null;
				
				if (dependencyProject == null || !dependencyProject.exists())
				{
					String swcPath = Potomac.getSWCPath(dependency);
					String targetPlat = Potomac.getTargetPlatform();
					if (swcPath.startsWith("${"+Activator.TARGETPLAT_PATHVAR+"}"))
					{
						swcPath = swcPath.substring(("${"+Activator.TARGETPLAT_PATHVAR+"}").length());
						swcPath = targetPlat + swcPath;
					}
					
					SWCFileSpecification swcFile = new SWCFileSpecification(swcPath);
					
					SWCFileNode parseFile = SWCFileHandler.getHandler().parseFile(swcFile);
					parseFile.postProcess();
					
					IDefinition defs[] = parseFile.getAllTopLevelDefinitions(false, false);
					
					String varType = var.getVariableType();

					for (IDefinition def : defs)
					{
						if (varType.equals(def.getQualifiedName()))
						{
							type = (IType) def;
							break;
						}
						if (varType.equals(def.getShortName()))
						{
							for (String imp : imports)
							{
								if (imp.equals(def.getQualifiedName()))
								{
									type = (IType) def;
									break;
								}
								if (imp.equals(def.getPackageName() + ".*"))
								{
									type = (IType) def;
									break;
								}
							}
							
							if (type != null)
								break;
						}
					}
					
					if (type != null)
						break;
				}
				else
				{
					flexProject = CMFactory.getManager().getProjectFor(dependencyProject);
				}

				
				if (flexProject == null)
					continue;
				
				IClassNameIndex index = (IClassNameIndex) flexProject.getIndex(IClassNameIndex.ID);
				
				if (index == null)
					continue;
				
				IClass clz = index.getByAsIsName(var.getVariableType(), imports);
				if (clz != null)
				{
					type = clz;
					break;
				}
				if (type == null)
				{
					IInterfaceNameIndex iIndex = (IInterfaceNameIndex) flexProject.getIndex(IInterfaceNameIndex.ID);
					IInterface ifc = iIndex.getByAsIsName(var.getVariableType(), imports);
					if (ifc != null)
					{
						type = ifc;
						break;
					}
				}
			}
		}
		
		if (type == null){
			return null;
		}

		return type.getQualifiedName();
	}
	
	
	
	
	@Override
	protected void clean(IProgressMonitor monitor) throws CoreException {
		Potomac.log("Cleaning markers");
		getProject().deleteMarkers(MARKER_TYPE, false, IResource.DEPTH_INFINITE);
		Potomac.log("Markers cleaned");

		try
		{
			IFolder bin = getProject().getFolder(Potomac.getOutputDirectory(getProject()));
			IFile swf = bin.getFile(getProject().getName() + ".swf");
			if (swf.exists())
			{
				swf.setReadOnly(false);
				swf.delete(true,null);
			}
			
			
			IFile bundlexml = bin.getFile("bundle.xml");
			if (bundlexml.exists())
			{
				bundlexml.setReadOnly(false);
				bundlexml.delete(true,null);
			}
			
			IFolder assets = bin.getFolder("assets");
			if (assets.exists())
			{
				assets.setReadOnly(false);
				Potomac.setAllWritable(assets);
				assets.delete(true,null);
			}
			
			IFile assetSWF = bin.getFile(ASSETS_SWF);
			if (assetSWF.exists())
			{
				assetSWF.setReadOnly(false);
				assetSWF.delete(true,null);
			}
		} catch (CoreException e)
		{
			//Usually some sort of locking error on one of the files/directories
			IMarker marker = getProject().createMarker(MARKER_TYPE);
			marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
			marker.setAttribute(IMarker.MESSAGE, "Unable to delete files in \\bin during project clean. Please retry.");
		}
	}
	
	private static boolean compareLists(ArrayList<HashMap<String,String>> compare1, ArrayList<HashMap<String,String>> compare2)
	{
		if (compare1.size() != compare2.size()) 
			return false;
		
		for(HashMap<String,String> map : compare1)
		{
			boolean foundSame = false;
			
			for (HashMap<String,String> map2 : compare2)
			{
				boolean equal = false;
				if (map.size() == map2.size())
				{
					equal = true;
					for (String key : map.keySet())
					{
						if (!map2.containsKey(key) || !map.get(key).equals(map2.get(key)))
						{
							equal = false;
							break;
						}
					}
				}
				
				if (equal)
				{
					foundSame = true;
					break;
				}
			}
			
			if (!foundSame)
				return false;
		}
		
		return true;
	}
}
