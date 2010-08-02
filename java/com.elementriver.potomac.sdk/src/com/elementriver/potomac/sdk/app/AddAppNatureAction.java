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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IAdaptable;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.jface.action.IAction;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IObjectActionDelegate;
import org.eclipse.ui.IWorkbenchPart;
import org.eclipse.ui.PlatformUI;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.project.ClassPathEntryFactory;
import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;
import com.elementriver.potomac.sdk.Potomac;
import com.elementriver.potomac.sdk.PotomacConstants;

public class AddAppNatureAction implements IObjectActionDelegate {

	private ISelection selection;

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.eclipse.ui.IActionDelegate#run(org.eclipse.jface.action.IAction)
	 */
	public void run(IAction action) {
		if (selection instanceof IStructuredSelection) {
			for (Iterator it = ((IStructuredSelection) selection).iterator(); it
					.hasNext();) {
				Object element = it.next();
				IProject project = null;
				if (element instanceof IProject) {
					project = (IProject) element;
				} else if (element instanceof IAdaptable) {
					project = (IProject) ((IAdaptable) element)
							.getAdapter(IProject.class);
				}
				if (project != null) {
					toggleNature(project);
				}
			}
		}
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.eclipse.ui.IActionDelegate#selectionChanged(org.eclipse.jface.action.IAction,
	 *      org.eclipse.jface.viewers.ISelection)
	 */
	public void selectionChanged(IAction action, ISelection selection) {
		this.selection = selection;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.eclipse.ui.IObjectActionDelegate#setActivePart(org.eclipse.jface.action.IAction,
	 *      org.eclipse.ui.IWorkbenchPart)
	 */
	public void setActivePart(IAction action, IWorkbenchPart targetPart) {
	}

	/**
	 * Toggles sample nature on a project
	 * 
	 * @param project
	 *            to have sample nature added or removed
	 */
	private void toggleNature(IProject project) {
		
		if (!MessageDialog.openConfirm(null,"Transform into Potomac Application?","Would you like to transform this Flex Project into a Potomac Application Project?  The project's settings and build path will be reconfigured as necessary."))
			return;
		
		try {

			if (!CMFactory.getRegistrar().isProjectRegistered(project))
			{
				CMFactory.getRegistrar().registerProject(project,null);
			}
	
			synchronized (CMFactory.getLockObject())
	   	 	{
				IActionScriptProject proj = ActionScriptCore.getProject(project);
				
				ActionScriptProjectSettings flexProjectSettings = ( ActionScriptProjectSettings ) proj.getProjectSettings();
				ArrayList<IClassPathEntry> libraryPaths = new ArrayList<IClassPathEntry>(Arrays.asList(flexProjectSettings.getLibraryPath()));

				flexProjectSettings.setAdditionalCompilerArgs(flexProjectSettings.getAdditionalCompilerArgs() + " -keep-all-type-selectors=true");
				
				boolean refExists = false;
				for (IClassPathEntry libPath : libraryPaths)
				{
					IPath linkablePath = libPath.getLinkablePath();
					if (linkablePath != null && linkablePath.toString().endsWith(PotomacConstants.POTOMAC_CORE_BUNDLEID + ".swc"))
					{
						refExists = true;
						break;
					}
				}	
				
				for (IClassPathEntry libPath : libraryPaths)
				{
					IClassPathEntry kids[] = libPath.getChildLibraries(null);
					for (IClassPathEntry libPath2 : kids)
					{
						IPath linkablePath = libPath2.getLinkablePath();
						if (linkablePath != null && linkablePath.toString().endsWith("rpc.swc"))
						{
							libPath2.setLinkType(IClassPathEntry.LINK_TYPE_RSL);
							libPath2.setRslUrl("rpc.swf");
							libPath2.setAutoExtractSwf(true);
							break;
						}
					}
				}	
				
				if (!refExists)
				{
					String coreSWC = Potomac.getSWCPath(PotomacConstants.POTOMAC_CORE_BUNDLEID);
					IClassPathEntry classPathEntry = ClassPathEntryFactory.newEntry(IClassPathEntry.KIND_LIBRARY_FILE,coreSWC, flexProjectSettings );
					classPathEntry.setLinkType(IClassPathEntry.LINK_TYPE_RSL);
					classPathEntry.setRslUrl(PotomacConstants.POTOMAC_CORE_BUNDLEID + ".swf");
					classPathEntry.setAutoExtractSwf(true);
					libraryPaths.add( classPathEntry );	
					flexProjectSettings.setLibraryPath( libraryPaths.toArray( new IClassPathEntry[ libraryPaths.size() ] ) );
					flexProjectSettings.setDefaultLinkType(IClassPathEntry.LINK_TYPE_RSL);
					flexProjectSettings.saveDescription(project, new NullProgressMonitor());					
				}
				else
				{
					flexProjectSettings.setDefaultLinkType(IClassPathEntry.LINK_TYPE_RSL);
					flexProjectSettings.saveDescription(project, new NullProgressMonitor());
				}

	   	 	}
			
			
			
			IProjectDescription description = project.getDescription();
			String[] natures = description.getNatureIds();


			// Add the nature
			String[] newNatures = new String[natures.length + 1];
			System.arraycopy(natures, 0, newNatures, 0, natures.length);
			newNatures[natures.length] = PotomacAppNature.NATURE_ID;
			description.setNatureIds(newNatures);
			project.setDescription(description, null);
			
			if (!project.getFile("appManifest.xml").exists())
			{
				ManifestModel model = new ManifestModel(null);
				model.bundles.add(PotomacConstants.POTOMAC_CORE_BUNDLEID);
				model.preloads.add(PotomacConstants.POTOMAC_CORE_BUNDLEID);
				model.save(project.getFile("appManifest.xml"));
			}
						
		} catch (CoreException e) {
			MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(),"Error Adding Nature",e.getMessage());
		}
	}

}
