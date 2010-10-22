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
package com.elementriver.potomac.sdk;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.core.runtime.Status;
import org.eclipse.swt.custom.BusyIndicator;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.codemodel.definitions.IClass;
import com.adobe.flexbuilder.codemodel.definitions.IDefinition;
import com.adobe.flexbuilder.codemodel.indices.IClassNameIndex;
import com.adobe.flexbuilder.codemodel.tree.IFileNode;
import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;
import com.elementriver.potomac.sdk.bundles.PotomacBundleNature;

public class Potomac {
	
	public static void log(String message)
	{
		if (Activator.getDefault().getPreferenceStore().getBoolean(PreferenceConstants.LOGGING))
		{
			Activator.getDefault().getLog().log(new Status(Status.INFO,Activator.PLUGIN_ID,"[POTOMAC]" +message));
		}
	}
	
	public static String getTargetPlatform()
	{
		return Activator.getDefault().getPreferenceStore().getString(PreferenceConstants.TARGET_PLATFORM);
	}
	
	public static ArrayList<String> getBundles() throws CoreException
	{
		ArrayList<String> bundles = new ArrayList<String>();
		
		IProject[] projs = ResourcesPlugin.getWorkspace().getRoot().getProjects();
		
		for (int i = 0; i < projs.length; i++) {
			if (!projs[i].isOpen())
				continue;
			if (projs[i].hasNature(PotomacBundleNature.NATURE_ID))
			{
				bundles.add(projs[i].getName());
			}
		}
		
		String targetPlat = getTargetPlatform();
		
        if (targetPlat == null || targetPlat.trim().equals(""))
        {
        	return bundles;
        }
		
        File platform = new File(targetPlat);
        
        if (!platform.exists())
        {
        	return bundles;
        }
        
        File[] subdirs = platform.listFiles();
        for (int i = 0; i < subdirs.length; i++) {
			if (subdirs[i].isDirectory())
			{
				//make sure its got a bundle.xml
				if (new File(subdirs[i],"bundle.xml").exists())
				{
					bundles.add(subdirs[i].getName());
				}
			}
		}
        
		return bundles;
	}
	
	public static File getBundleXML(String id,boolean binVersion)
	{
		IWorkspace workspace = ResourcesPlugin.getWorkspace();
		if (workspace.getRoot().getProject(id).exists())
		{
			if (!workspace.getRoot().getProject(id).isOpen())
			{
				try {
					workspace.getRoot().getProject(id).open(new NullProgressMonitor());
				} catch (CoreException e) {
					e.printStackTrace();
					throw new RuntimeException(e);
				}
			}
			if (binVersion)
			{				
				return workspace.getRoot().getProject(id).getFile(getOutputDirectory(workspace.getRoot().getProject(id)) + "/bundle.xml").getLocation().toFile();
			}
			else
			{
				return workspace.getRoot().getProject(id).getFile("bundle.xml").getLocation().toFile();
			}
		}
		else
		{
			return new File(getTargetPlatform(), "/" + id + "/bundle.xml");
		}
	}

	public static String getSourceDirectory(IResource rezInProject)
	{
		IProject proj = rezInProject.getProject();
		if (!CMFactory.getRegistrar().isProjectRegistered(proj))
		{
			CMFactory.getRegistrar().registerProject(proj,null);
		}	
		
		String dir = "";
		synchronized (CMFactory.getLockObject())
   	 	{
			dir = ActionScriptCore.getProject(proj).getProjectSettings().getMainSourceFolder().toString();
   	 	}
		return dir;
	}

	public static String getOutputDirectory(IResource rezInProject)
	{
		IProject proj = rezInProject.getProject();
		if (!CMFactory.getRegistrar().isProjectRegistered(proj))
		{
			CMFactory.getRegistrar().registerProject(proj,null);
		}	
		
		String dir = "";
		synchronized (CMFactory.getLockObject())
   	 	{
			dir = ActionScriptCore.getProject(proj).getProjectSettings().getOutputFolder().toString();
   	 	}
		return dir;
	}
	
	public static String getFlexClassName(IFile file)
	{
		IProject proj = file.getProject();
		if (!CMFactory.getRegistrar().isProjectRegistered(proj))
		{
			CMFactory.getRegistrar().registerProject(proj,null);
		}		
		
		String name = "";
		synchronized (CMFactory.getLockObject())
   	 	{
			IFileNode node = CMFactory.getManager().getProjectFor(proj).findFileNodeInProject(file.getLocation());
			name = node.getAllTopLevelDefinitions(true,false)[0].getQualifiedName();
   	 	}
		return name;
	}

	public static IFile getFileFromFlexClassName(String className,IProject proj)
	{
		if (!CMFactory.getRegistrar().isProjectRegistered(proj))
		{
			CMFactory.getRegistrar().registerProject(proj,null);
		}
		
		synchronized (CMFactory.getLockObject())
   	 	{
			IClassNameIndex index = (IClassNameIndex) CMFactory.getManager().getProjectFor(proj).getIndex(IClassNameIndex.ID);
			IDefinition clazz = index.getByQualifiedName(className);
			
			if (clazz == null) return null;
	
			return proj.getWorkspace().getRoot().getFileForLocation(new Path(clazz.getContainingSourceFilePath()));
   	 	}

	}
	
	public static String getSWCPath(String id)
	{
		String path = "";
		
		IWorkspace workspace = ResourcesPlugin.getWorkspace();
		if (workspace.getRoot().getProject(id).exists())
		{
			path = "/" + id + "/" + getOutputDirectory(workspace.getRoot().getProject(id)) + "/" + id + ".swc";
		}
		else
		{
			path = "${"+Activator.TARGETPLAT_PATHVAR+"}" + "/" + id + "/" + id + ".swc";
		}
		return path;
	}
	
	public static String getAssetsPath(String id)
	{
		String path = "";
		
		IWorkspace workspace = ResourcesPlugin.getWorkspace();
		if (workspace.getRoot().getProject(id).exists())
		{
			path = "/" + id + "/" + getOutputDirectory(workspace.getRoot().getProject(id)) + "/extensionAssets";
		}
		else
		{
			path = Activator.TARGETPLAT_PATHVAR + "/" + id + "/extensionAssets";
		}
		return path;		
	}
	
	public static CoreException createCoreException(String message,Exception e)
	{
		Status status = new Status(IStatus.ERROR,Activator.PLUGIN_ID,message,e);
		return new CoreException(status);
	}
	
	public static void updateBuidPath(final IProject project,final ArrayList<String> bundlesInPath)
	{
		BusyIndicator.showWhile(null, new Runnable() {
			public void run() {

				ActionScriptProjectSettings flexProjectSettings = null;
				
				if (!CMFactory.getRegistrar().isProjectRegistered(project))
				{
					CMFactory.getRegistrar().registerProject(project,null);
				}
				
				ArrayList<IClassPathEntry> libraryPaths = null;
				
				IActionScriptProject proj = ActionScriptCore.getProject(project);
							
				flexProjectSettings = ( ActionScriptProjectSettings ) proj.getProjectSettings();
				libraryPaths = new ArrayList<IClassPathEntry>(Arrays.asList(flexProjectSettings.getLibraryPath()));

				for (IClassPathEntry entry : libraryPaths)
				{
					if (entry.getKind() != IClassPathEntry.KIND_LIBRARY_FILE)
						continue;
					
					//check to see if this entry is a reference to a bundle
					for (String bundle : bundlesInPath)
					{
						if (entry.getValue().contains("/"+bundle+"/"))
						{
							//if it is a bundle reference, update its path
							String swcPath = Potomac.getSWCPath(bundle);	
							entry.setValue(swcPath);
							break;
						}
					}				
				}	

				flexProjectSettings.setLibraryPath( libraryPaths.toArray( new IClassPathEntry[ libraryPaths.size() ] ) );
				try
				{
					proj.setProjectDescription(flexProjectSettings, new NullProgressMonitor());
				} catch (CoreException e)
				{
				}
				
				UpdateBuildPathJob job = new UpdateBuildPathJob();
				job.project = project;
				job.settings = flexProjectSettings;
				job.setRule(UpdateBuildPathJob.getRule(project));
				job.schedule();
				
			}
		});		
	}
	
	public static ArrayList<IClass> getAllClassesInProject(IProject project, String instanceOf) throws CoreException
	{
		if (!CMFactory.getRegistrar().isProjectRegistered(project))
		{
			CMFactory.getRegistrar().registerProject(project,null);
		}	
		
		IClassPathEntry srcPaths[] = ActionScriptCore.getProject(project).getProjectSettings().getSourcePath();

		ArrayList<IClass> types = new ArrayList<IClass>();
		
		synchronized (CMFactory.getLockObject())
   	 	{
			for (int i = 0; i < srcPaths.length; i++)
			{
				IClassPathEntry iCPE = srcPaths[i];
				
				IFolder folder = ResourcesPlugin.getWorkspace().getRoot().getFolder(iCPE.getResolvedPath());
				
				types.addAll(getAllClassesInFolder(iCPE.getResolvedPath().makeAbsolute().toFile(),project, instanceOf));
				
			}
			
			File file = project.getFile(ActionScriptCore.getProject(project).getProjectSettings().getMainSourceFolder()).getLocation().makeAbsolute().toFile();
			ArrayList<IClass> clzes = getAllClassesInFolder(file, project, instanceOf);
			for (IClass clz : clzes)
			{
				if (!types.contains(clz))
					types.add(clz);
			}
   	 	}
		
		return types;
	}
   
	public static ArrayList<IDefinition> getAllDefinitionsInProject(IProject project) throws CoreException
	{
		if (!CMFactory.getRegistrar().isProjectRegistered(project))
		{
			CMFactory.getRegistrar().registerProject(project,null);
		}	
		
		IClassPathEntry srcPaths[] = ActionScriptCore.getProject(project).getProjectSettings().getSourcePath();

		ArrayList<IDefinition> defs = new ArrayList<IDefinition>();
		
		synchronized (CMFactory.getLockObject())
   	 	{
			for (int i = 0; i < srcPaths.length; i++)
			{
				IClassPathEntry iCPE = srcPaths[i];
				
				IPath path = iCPE.getResolvedPath();
				
				defs.addAll(getAllDefinitionsInFolder(path.toFile(),project));
				
			}
			
			File file = project.getFile(ActionScriptCore.getProject(project).getProjectSettings().getMainSourceFolder()).getLocation().makeAbsolute().toFile();
			ArrayList<IDefinition> defs2 = getAllDefinitionsInFolder(file, project);
			for (IDefinition def : defs2)
			{
				if (!defs.contains(def))
					defs.add(def);
			}
   	 	}
		
		return defs;
	}
	
	private static ArrayList<IDefinition> getAllDefinitionsInFolder(File folder,IProject project) throws CoreException
	{		
		ArrayList<IDefinition> defs = new ArrayList<IDefinition>();
		
		if (!folder.exists())
			return defs;
		
		com.adobe.flexbuilder.codemodel.project.IProject flexProj = CMFactory.getManager().getProjectFor(project);
		

		for (File member : folder.listFiles())
		{
			if (member.isFile())
			{
				IFileNode node = flexProj.findFileNodeInProject(new Path(member.getAbsolutePath()));
				if (node != null)
				{
					IDefinition topDefs[] = node.getAllTopLevelDefinitions(true,true);
					for (IDefinition def : topDefs)
					{
						if (!defs.contains(def))
							defs.add(def);
					}
				}
			}
			else if (member.isDirectory())
			{
				ArrayList<IDefinition> defs2 = getAllDefinitionsInFolder(member,project);
				for (IDefinition def : defs2)
				{
					if (!defs.contains(def))
						defs.add(def);
				}
			}
		}

		return defs;
	}
	
	private static ArrayList<IClass> getAllClassesInFolder(File folder, IProject project, String instanceOf) throws CoreException
	{
		ArrayList<IClass> types = new ArrayList<IClass>();
		
		if (!folder.exists())
			return types;
		
		com.adobe.flexbuilder.codemodel.project.IProject flexProj = CMFactory.getManager().getProjectFor(project);

		for (File member : folder.listFiles())
		{
			if (member.isFile())
			{
				IFileNode node = flexProj.findFileNodeInProject(new Path(member.getAbsolutePath()));
				if (node != null)
				{
					IDefinition defs[] = node.getAllTopLevelDefinitions(true,true);
					for (IDefinition def : defs)
					{
						if (instanceOf != null)
						{
							if (def instanceof IClass && ((IClass)def).isInstanceOf(instanceOf))
							{
								if (!types.contains((IClass)def))
										types.add((IClass) def);	
							} 
						}
						else if (def instanceof IClass)
						{
							if (!types.contains((IClass)def))
								types.add((IClass) def);	
						}
					}
				}
			}
			else if (member.isDirectory())
			{
				ArrayList<IClass> clzes = getAllClassesInFolder(member,project,instanceOf);
				for (IClass clz : clzes)
				{
					if (!types.contains(clz))
						types.add(clz);
				}
			}
		}

		return types;
	}
	
	public static void setAllWritable(IFolder folder)
	{
		folder.setReadOnly(false);
		IResource members[];
		try {
			members = folder.members();
		} catch (CoreException e) {
			throw new RuntimeException(e);
		}
		for (IResource member : members)
		{
			member.setReadOnly(false);
			if (member instanceof IFolder)
			{
				setAllWritable((IFolder) member);
			}
		}
	}
}
