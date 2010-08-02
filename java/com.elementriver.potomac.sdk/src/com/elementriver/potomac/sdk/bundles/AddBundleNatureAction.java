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

import java.util.Iterator;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IAdaptable;
import org.eclipse.jface.action.IAction;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.IObjectActionDelegate;
import org.eclipse.ui.IWorkbenchPart;


public class AddBundleNatureAction implements IObjectActionDelegate {

	private ISelection selection;

	
	public AddBundleNatureAction() {
		// TODO Auto-generated constructor stub
	}

	
	public void setActivePart(IAction action, IWorkbenchPart targetPart) {
		// TODO Auto-generated method stub
		
	}

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


	public void selectionChanged(IAction action, ISelection selection) {
		this.selection = selection;
		
	}
	
	private void toggleNature(IProject project) {
		
		if (!MessageDialog.openConfirm(null,"Transform into Potomac Bundle?","Would you like to transform this Flex Library Project into a Potomac Bundle Project?"))
				return;
		
		try {
			IProjectDescription description = project.getDescription();
			String[] natures = description.getNatureIds();

			// Add the nature
			String[] newNatures = new String[natures.length + 1];
			System.arraycopy(natures, 0, newNatures, 0, natures.length);
			newNatures[natures.length] = PotomacBundleNature.NATURE_ID;
			description.setNatureIds(newNatures);
			project.setDescription(description, null);
			
			if (!project.getFile("bundle.xml").exists())
			{
				BundleModelManager.getInstance().createAndSaveModel(project.getName());
			}
		} catch (CoreException e) {
			e.printStackTrace();
			MessageDialog.openError(null,"Error setting nature",e.getMessage());
		}
	}

}
