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
package com.elementriver.potomac.sdk.app;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceDelta;
import org.eclipse.core.resources.IResourceVisitor;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.IWorkspaceRunnable;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.ui.PlatformUI;

import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;
import com.elementriver.potomac.sdk.Potomac;
import com.elementriver.potomac.sdk.bundles.BundleModel;
import com.elementriver.potomac.sdk.bundles.BundleModelManager;
import com.elementriver.potomac.sdk.bundles.PotomacBundleBuilder;

public class PotomacAppBuilder extends IncrementalProjectBuilder {

	public static final String BUILDER_ID = "com.elementriver.potomac.sdk.potomacAppBuilder";
	
	private boolean doBundleCopy = true;
	private boolean doAppInitCreation = true;
	private boolean doAppManifestValidation = false;

	protected IProject[] build(int kind, Map args, IProgressMonitor monitor)
			throws CoreException {
		//System.out.println("AppBuild on " + getProject());

//		if (kind == CLEAN_BUILD)
//			System.out.println("CLEAN");
//		if (kind == FULL_BUILD)
//			System.out.println("FULL");
//		if (kind == AUTO_BUILD)
//			System.out.println("AUTO");
//		if (kind == INCREMENTAL_BUILD)
//			System.out.println("INCREMENTAL");
		
		if (kind == CLEAN_BUILD || kind == FULL_BUILD)
		{
			doBundleCopy = true;
			doAppInitCreation = true;
			doAppManifestValidation = true;
		}
		else
		{
			doBundleCopy = false;
			doAppInitCreation = false;
			
			IResourceDelta delta = getDelta(getProject());
			if (delta != null && delta.findMember(new Path("appManifest.xml")) != null)
			{
				doBundleCopy = true;
				doAppInitCreation = true;
				doAppManifestValidation = true;
			}
			else
			{
				IProject referencedProjs[] = getProject().getReferencedProjects();
				for (IProject refProj : referencedProjs)
				{
					delta = getDelta(refProj);
					if (delta == null)
					{
						continue;
					}
	
					if (delta.findMember(new Path(Potomac.getOutputDirectory(refProj) + "/" + refProj.getName() + ".swf")) != null)
					{
						doBundleCopy = true;
					}
					if (delta.findMember(new Path("bundle.xml")) != null )
					{
						doBundleCopy = true;
						doAppInitCreation = true;
					}
				}
			}
		}

		//System.out.println("bundle = " + doBundleCopy + "; cargo = " + doCargoCreation + "; asset = " + doAssetCreation);
		
		getProject().deleteMarkers(PotomacBundleBuilder.MARKER_TYPE, false, IResource.DEPTH_ZERO);
		
		if (!getProject().getFile("appManifest.xml").exists())
		{			
			Potomac.log("Creating marker for appManifest");
			IMarker marker = getProject().createMarker(PotomacBundleBuilder.MARKER_TYPE);
			marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
			marker.setAttribute(IMarker.MESSAGE, "Potomac App must have an appManifest.xml in the root.");
			Potomac.log("Marker created");
		}
		else
		{
			fullBuild();	
		}
		
		//System.out.println("AppBuild finished on " + getProject());
		return getProject().getReferencedProjects();
	}

	private void fullBuild() throws CoreException
	{
		ManifestModel model = new ManifestModel(getProject().getFile("appManifest.xml"));
		
		//Temporary code
		//This code is to remove any bundle RSLs from the build path
		//we changed from rsls to a Potomac specific preload feature, therefore we shouldnt need any rsls in the build path
		IActionScriptProject asProj = ActionScriptCore.getProject(getProject());
		
		ActionScriptProjectSettings flexProjectSettings = ( ActionScriptProjectSettings ) asProj.getProjectSettings();
		ArrayList<IClassPathEntry> libraryPaths = new ArrayList<IClassPathEntry>(Arrays.asList(flexProjectSettings.getLibraryPath()));

		for (IClassPathEntry classPathEntry : libraryPaths.toArray(new IClassPathEntry[]{}))
		{
			if (classPathEntry.getKind() != IClassPathEntry.LINK_TYPE_RSL)
				continue;
			
			String name = classPathEntry.getValue();	
			
			for (String bundle : model.bundles)
			{
				if (bundle.equals("potomac_core")) //core should stay an RSL
					continue;
				
				if (name.contains(bundle + ".swc"))
					libraryPaths.remove(classPathEntry);
			}
			
		}
		
		flexProjectSettings.setLibraryPath( libraryPaths.toArray( new IClassPathEntry[ libraryPaths.size() ] ) );
		//end temp code
		
		
		
		
		
		
		String srcDir = Potomac.getSourceDirectory(getProject());
		
		IFolder folder = getProject().getFolder(srcDir + "/potomac");
		if (!folder.exists())
		{
			folder.create(true,false,null);
		}
		folder = getProject().getFolder(srcDir + "/potomac/derived");
		if (!folder.exists())
		{
			folder.create(true,false,null);
		}
		
		if (doAppManifestValidation)
		{
			getProject().getFile("appManifest.xml").deleteMarkers(PotomacBundleBuilder.MARKER_TYPE, false, IResource.DEPTH_ZERO);
			if (model.getTemplateParameters(model.templateID,model.bundles) == null)
			{
				Potomac.log("Creating marker - appManifest/UI template");
				IMarker marker = getProject().getFile("appManifest.xml").createMarker(PotomacBundleBuilder.MARKER_TYPE);
				marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
				marker.setAttribute(IMarker.MESSAGE,"UI Template is not selected or selected template is invalid.");
				Potomac.log("Marker created");
			}
			
			for (String bundle : model.bundles)
			{			
				BundleModel bundleModel = BundleModelManager.getInstance().getModel(bundle);
				
				//ensure dependencies are all found
				for (String depend : bundleModel.dependencies)
				{
					if (!model.bundles.contains(depend))
					{
						Potomac.log("Creating marker - appManifest/depends");
						IMarker marker = getProject().getFile("appManifest.xml").createMarker(PotomacBundleBuilder.MARKER_TYPE);
						marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
						marker.setAttribute(IMarker.MESSAGE,"Bundle '" + bundle + "' depends on bundle '" + depend +"' which is not included in the application's bundle list.");
						Potomac.log("Marker created");
					}
				}
		
				//ensure this bundle is an preload if one of its extensions is an preload only extension
				for (HashMap<String,String> ext : bundleModel.extensions)
				{
					HashMap<String,String> extPt = BundleModelManager.getInstance().getExtensionPoint(ext.get("point"));
					if (!model.preloads.contains(bundle) && extPt.get("preloadRequired") != null && extPt.get("preloadRequired").equals("true"))
					{
						Potomac.log("Creating marker - appManifest/preload");
						IMarker marker = getProject().getFile("appManifest.xml").createMarker(PotomacBundleBuilder.MARKER_TYPE);
						marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
						marker.setAttribute(IMarker.MESSAGE, "Bundle '" + bundle +"' must be preloaded.  It contains one or more extensions which require the bundle to be preloaded.");
						Potomac.log("Marker created");
						break;
					}
				}
			}
		}
		
		if (doBundleCopy)
		{					
			
			IFolder bundlesFolder = cleanBundlesFolder();
			bundlesFolder.create(IResource.DERIVED | IResource.FORCE, true, null);		

			for (String bundle : model.bundles)
			{
				IProject proj = getProject().getWorkspace().getRoot().getProject(bundle);
				if (proj.exists())
				{
					String outputDir = Potomac.getOutputDirectory(proj);
					IFolder outputFolder = proj.getFolder(outputDir);
					if (outputFolder.exists())
					{
						outputFolder.copy(bundlesFolder.getFolder(bundle).getFullPath(), IResource.DERIVED | IResource.FORCE, null);
					}
				}
				else //in target platform
				{
					File binBundleFolder = bundlesFolder.getFolder(bundle).getLocation().toFile();
					File bundleFolder = new File(Potomac.getTargetPlatform() + "/" + bundle);
					try {
						copyDirectory(bundleFolder, binBundleFolder);
					} catch (IOException e) {
						throw Potomac.createCoreException("Unable to copy bundle from target platform.", e);
					}
				}
			}
					
			bundlesFolder.refreshLocal(IResource.DEPTH_INFINITE, null);
			bundlesFolder.accept(new IResourceVisitor(){
			public boolean visit(IResource resource) throws CoreException {
				resource.setDerived(true);
				return true;
			}});
			
			
		}
			
				
		String newline = System.getProperty("line.separator");
		
//		if (doAppInitCreation)
//		{
//			String cargoXML = "<application>" + newline;
//			cargoXML += "<bundles>" + newline;
//			
//			for (String bundle : model.bundles)
//			{
//				String rsl = "false";
//				if (model.rslPreloads.contains(bundle))
//					rsl = "true";
//				cargoXML += "   <bundle rsl='"+rsl+"'>" + bundle + "</bundle>" + newline;
//			}	
//			
//			cargoXML += "</bundles>" + newline;
//			
//			cargoXML += "<rsl_xml>" + newline;
//			
//			for (String rsl : model.rslPreloads)
//			{
//				cargoXML += "   " + BundleModelManager.getInstance().getBundleXMLString(rsl,true);
//			}
//				
//			cargoXML += "</rsl_xml>" + newline;
//			
//			cargoXML += "</application>";
//			
//			InputStream is = null;
//			try {
//				is = new ByteArrayInputStream(cargoXML.getBytes("UTF-8"));
//			} catch (UnsupportedEncodingException e) {
//				// TODO Auto-generated catch block
//				e.printStackTrace();
//			}
//			
//			IFile cargo = getProject().getFile(Potomac.getOutputDirectory(getProject()) + "/appCargo.xml");
//			
//			try {
//				if (cargo.exists())
//				{
//					cargo.setReadOnly(false);
//					cargo.setContents(is, true,true, null);
//				}
//				else
//				{
//					cargo.create(is, true,null);
//				}
//			} catch (CoreException e) {
//				throw Potomac.createCoreException("Error writing cargo file during build.", e);
//			}
//			
//			//Don't set derived, flex won't compile it
//			//cargo.setDerived(true);
//			
//			needRebuild();
//		}
		
		

//		if (doAssetCreation)
//		{
//			StringBuilder assetsFileContents = new StringBuilder();
//			assetsFileContents.append("package potomac.derived {" + newline);
//			assetsFileContents.append("   public class ExtensionAssets {" + newline);
//			
//					
//			for (String bundle : model.bundles)
//			{
//				File ioFolder = null;
//				IFolder eclipseFolder = null;
//				boolean hasAssets = false;
//				IProject project = getProject().getWorkspace().getRoot().getProject(bundle);
//				if (project.exists())
//				{
//					eclipseFolder = project.getFolder(new Path("extensionAssets"));
//					hasAssets = eclipseFolder.exists();
//				}
//				else
//				{
//					IPath path = new Path(Potomac.getAssetsPath(bundle));
//					path = getProject().getWorkspace().getPathVariableManager().resolvePath(path);
//					ioFolder = path.toFile();
//					hasAssets = ioFolder.exists() && ioFolder.isDirectory();
//				}
//	
//				if (hasAssets)
//				{
//					addAssetsToCode(bundle, ioFolder,eclipseFolder, assetsFileContents);
//				}			
//			}
//			
//			assetsFileContents.append("   }" + newline + "}");		
//			
//			InputStream is = null;
//			try {
//				is = new ByteArrayInputStream(assetsFileContents.toString().getBytes("UTF-8"));
//			} catch (UnsupportedEncodingException e) {
//				// TODO Auto-generated catch block
//				e.printStackTrace();
//			}
//			
//			IFile assetsClass = getProject().getFile(srcDir + "/potomac/derived/ExtensionAssets.as");
//			
//			try {
//				if (assetsClass.exists())
//				{
//					assetsClass.setReadOnly(false);
//					assetsClass.setContents(is, true,true, null);
//				}
//				else
//				{
//					assetsClass.create(is, true,null);
//				}
//				
//				//Don't set derived, flex won't compile it
//				//assetsClass.setDerived(true);
//			} catch (CoreException e) {
//				e.printStackTrace();
//				MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error Writing ExtensionAssets.as", "Unable to write ExtensionAssets.as.  " + e.getMessage());
//			}
//		
//			needRebuild();
//		}	
		
		//StyleReferences creation
//		if (!getProject().getFile(srcDir + "/potomac/derived/StyleReferences.as").exists())
//		{
//			StringBuilder styleRefFileContents = new StringBuilder();
//			styleRefFileContents.append("package potomac.derived {" + newline);
//			styleRefFileContents.append("   import mx.controls.*;" + newline);
//			styleRefFileContents.append("   import mx.containers.*;" + newline);
//			styleRefFileContents.append("   public class StyleReferences {" + newline);
//			
//			ArrayList<String> refs = StyleReferencesUtil.getClassesToReferences();
//			for (String ref : refs)
//			{
//				styleRefFileContents.append("      private var v" + ref + ":" + ref + ";" + newline);
//			}
//			
//			styleRefFileContents.append("   }" + newline);
//			styleRefFileContents.append(" }");
//			
//			InputStream is = null;
//			try {
//				is = new ByteArrayInputStream(styleRefFileContents.toString().getBytes("UTF-8"));
//			} catch (UnsupportedEncodingException e) {
//				e.printStackTrace();
//			}
//			
//			IFile styleClas = getProject().getFile(srcDir + "/potomac/derived/StyleReferences.as");
//			
//			try {
//
//				styleClas.create(is, true,null);
//				
//				//Don't set derived, flex won't compile it
//				//styleClas.setDerived(true);
//				styleClas.setReadOnly(true);
//			} catch (CoreException e) {
//				e.printStackTrace();
//				MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error Writing StyleReferences.as", "Unable to write StyleReferences.as.  " + e.getMessage());
//			}
//		
//			needRebuild();
//		}
		
		//do PotomacInitializer creation, we reuse the same cargo creation flag
		if (doAppInitCreation)
		{
			StringBuilder pInitContents = new StringBuilder();
			pInitContents.append("package potomac.derived {" + newline);
			pInitContents.append("   import flash.events.Event;" + newline);
			pInitContents.append("   import mx.core.FlexGlobals;" + newline);
			pInitContents.append("   import mx.events.FlexEvent;" + newline);
			pInitContents.append("   import potomac.core.Launcher;" + newline);
			pInitContents.append("   import potomac.core.LauncherManifest;" + newline);
			pInitContents.append("   import potomac.core.TemplateRunner;" + newline);
			pInitContents.append("   public class PotomacInitializer {" + newline);
				
			String bundles = "";
			String preloads = "";
			for (String bundle : model.bundles)
			{
				bundles += "\"" + bundle + "\",";
				
				if (model.preloads.contains(bundle))
					preloads += "\"" + bundle + "\",";
			}	
			
			if (bundles.endsWith(","))
				bundles = bundles.substring(0,bundles.length()-1);
			if (preloads.endsWith(","))
				preloads = preloads.substring(0,preloads.length()-1);
						
			pInitContents.append("      private var bundles:Array = ["+bundles+"];" + newline);
			pInitContents.append("      private var preloads:Array = ["+preloads+"];" + newline);
			
			
			
			
			pInitContents.append("      private var templateID:String = \""+model.templateID+"\";" + newline);
			pInitContents.append("      private var airBundlesURL:String = \""+model.airBundlesURL+"\";" + newline);
			pInitContents.append("      private var airDisableCaching:Boolean = "+model.airDisableCaching+";" + newline);
			
			String templateDataCode = "";
			HashMap<String,String> templatePropTypes = model.getTemplateParameters(model.templateID,model.bundles);
			for (String key : model.templateProperties.keySet())
			{
				String type = templatePropTypes.get(key);
				if (type.equals("image"))
				{
					if (model.templateProperties.get(key) != null && model.templateProperties.get(key).trim().length() > 0)
					{
						IFile file = getProject().getFile(model.templateProperties.get(key));
						if (file != null && file.exists())
						{
							String path = file.getLocation().makeAbsolute().toFile().getAbsolutePath();
							path = path.replace('\\','/');
							pInitContents.append("      [Embed(source=\""+path+"\")]" + newline);
							pInitContents.append("      private var templateProp_"+key+":Class;" + newline);
							templateDataCode += key + ":new templateProp_"+key+"(),";
						}
					}
				}
				else if (type.equals("boolean"))
				{
					String val = "false";
					if (model.templateProperties.get(key) != null && model.templateProperties.get(key).equals("true"))
						val = "true";
					templateDataCode += key + ":" + val + ",";
				}
				else
				{
					String val = "";
					if (model.templateProperties.get(key) != null)
						val = model.templateProperties.get(key);
					templateDataCode += key + ":\"" + val + "\",";
				}
			}
			if (templateDataCode.endsWith(","))
			{
				templateDataCode = templateDataCode.substring(0, templateDataCode.length() -1);
			}
			pInitContents.append("      private var templateData:Object = {"+templateDataCode+"};" + newline);
			
			String enableFlags = "";
			for (String flag : model.enablesForFlags)
			{
				enableFlags += "\"" + flag + "\",";
			}
			if (enableFlags.endsWith(","))
				enableFlags = enableFlags.substring(0,enableFlags.length() -1);
			
			pInitContents.append("      private var enablesForFlags:Array = ["+enableFlags+"];" + newline);
			pInitContents.append("      public function PotomacInitializer(){" + newline);
			pInitContents.append("         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.APPLICATION_COMPLETE,go);" + newline);
			pInitContents.append("         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.INITIALIZE,init);" + newline);
			pInitContents.append("      }" + newline);
			pInitContents.append("      public function init(e:Event):void {" + newline);
			pInitContents.append("         Launcher.findPreloader();" + newline);
			pInitContents.append("      }" + newline);
			pInitContents.append("      public function go(e:Event):void {" + newline);
			pInitContents.append("         var runner:TemplateRunner = new TemplateRunner(templateID,templateData);" + newline);
			pInitContents.append("         var manifest:LauncherManifest = new LauncherManifest();" + newline);
			pInitContents.append("         manifest.bundles = bundles;" + newline);
			pInitContents.append("         manifest.preloads = preloads;" + newline);
			pInitContents.append("         manifest.airBundlesURL = airBundlesURL;" + newline);
			pInitContents.append("         manifest.disableAIRCaching = airDisableCaching;" + newline);
			pInitContents.append("         manifest.enablesForFlags = enablesForFlags;" + newline);
			pInitContents.append("         manifest.runner = runner;" + newline);
			pInitContents.append("         Launcher.launch(manifest);" + newline);
			pInitContents.append("      }" + newline);
			pInitContents.append("   }" + newline);
			pInitContents.append("}");
			
			InputStream is = null;
			try {
				is = new ByteArrayInputStream(pInitContents.toString().getBytes("UTF-8"));
			} catch (UnsupportedEncodingException e) {
				e.printStackTrace();
			}
			
			IFile initClass = getProject().getFile(srcDir + "/potomac/derived/PotomacInitializer.as");
			
			try {
				if (initClass.exists())
				{
					initClass.setReadOnly(false);
					initClass.setContents(is, true,true, null);
				}
				else
				{
					initClass.create(is, true,null);
				}
				
				//Don't set derived, flex won't compile it
				//initClass.setDerived(true);
			} catch (CoreException e) {
				e.printStackTrace();
				MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error Writing PotomacInitializer.as", "Unable to write PotomacInitializer.as.  " + e.getMessage());
			}
			
			needRebuild();
		}
	}

	private void addAssetsToCode(String bundle,File ioFolder,IFolder eclipseFolder,StringBuilder code) throws CoreException
	{
		String newline = System.getProperty("line.separator");
		
		if (ioFolder == null)
		{
			IResource assets[] = eclipseFolder.members();
			for (IResource asset : assets)
			{
				if (asset instanceof IFolder)
				{
					addAssetsToCode(bundle, null,(IFolder) asset, code);
				}
				else
				{
					String path = asset.getLocation().makeAbsolute().toFile().getAbsolutePath();
					
					path = path.replace('\\','/');
					code.append("      [Embed(source=\""+path+"\")]" + newline);
					
					path = path.substring(path.indexOf("extensionAssets") + "extensionAssets".length() + 1);
					path = path.replace('/','_');
					path = path.replace('.','_');
					path = path.replace(' ','_');
					String varName = bundle + "__" + path;
					
					
					code.append("      public var "+varName+":Class;" + newline);
					code.append(newline);
				}
			}
		}
		else
		{
			File assets[] = ioFolder.listFiles();
			for(File file : assets)
			{
				if (file.isDirectory())
				{
					addAssetsToCode(bundle, file,null, code);
				}
				else
				{
					String path = file.getAbsolutePath();
					
					path = path.replace('\\','/');
					code.append("      [Embed(source=\""+path+"\")]" + newline);
					
					path = path.substring(path.indexOf("extensionAssets") + "extensionAssets".length() + 1);
					path = path.replace('/','_');
					path = path.replace('.','_');
					path = path.replace(' ','_');
					String varName = bundle + "__" + path;
					
					
					code.append("      public var "+varName+":Class;" + newline);
					code.append(newline);
				}
			}
		}
	}
	
	@Override
	protected void clean(IProgressMonitor monitor) throws CoreException {

		try
		{
			getProject().deleteMarkers(PotomacBundleBuilder.MARKER_TYPE, false, IResource.DEPTH_INFINITE);
			cleanBundlesFolder();
			String srcDir = Potomac.getSourceDirectory(getProject());
			
			IFolder folder = getProject().getFolder(srcDir + "/potomac/derived");
			if (folder.exists())
			{
				folder.delete(true, null);
			}
		} catch (CoreException e)
		{
			//Usually some sort of locking error on one of the files/directories
			IMarker marker = getProject().createMarker(PotomacBundleBuilder.MARKER_TYPE);
			marker.setAttribute(IMarker.SEVERITY, IMarker.SEVERITY_ERROR);
			marker.setAttribute(IMarker.MESSAGE, "Unable to delete files during project clean. Please retry.");

		}
	}
	
	private IFolder cleanBundlesFolder() throws CoreException
	{
		String outputDir = Potomac.getOutputDirectory(getProject());
		IFolder outputBundles = getProject().getFolder(outputDir + "/bundles");
		
		if (!outputBundles.exists())
			return outputBundles;
		
		IWorkspaceRunnable runnable = new IWorkspaceRunnable() {
			public void run(IProgressMonitor monitor) throws CoreException {
				String outputDir = Potomac.getOutputDirectory(getProject());
				IFolder outputBundles = getProject().getFolder(outputDir + "/bundles");
				if (outputBundles.exists())
				{
					outputBundles.setReadOnly(false);
					Potomac.setAllWritable(outputBundles);
					outputBundles.delete(true, null);	
				}				
			}
		};
		
		getProject().getWorkspace().run(runnable, getProject().getWorkspace().getRuleFactory().deleteRule(outputBundles), IWorkspace.AVOID_UPDATE,null);
		
		return outputBundles;
	}
	
    public void copyDirectory(File sourceLocation, File targetLocation)
			throws IOException {

		if (sourceLocation.isDirectory()) {
			if (!targetLocation.exists()) {
				targetLocation.mkdir();
			}

			String[] children = sourceLocation.list();
			for (int i = 0; i < children.length; i++) {
				copyDirectory(new File(sourceLocation, children[i]), new File(
						targetLocation, children[i]));
			}
		} else {

			if (!sourceLocation.isHidden() && !sourceLocation.getName().startsWith("."))
			{
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
}
