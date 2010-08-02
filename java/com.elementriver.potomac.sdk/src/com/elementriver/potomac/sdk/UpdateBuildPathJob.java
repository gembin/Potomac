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

import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.resources.WorkspaceJob;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.core.runtime.jobs.ISchedulingRule;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;

public class UpdateBuildPathJob extends WorkspaceJob {
	
	public UpdateBuildPathJob() {
		super("Potomac Build Path Update");
	}

	public ActionScriptProjectSettings settings;
	public IProject project;
	public boolean clean = false;

	@Override
	public IStatus runInWorkspace(IProgressMonitor monitor)
			throws CoreException {

		settings.saveDescription(project,null);
		
		if (clean)
			project.build(IncrementalProjectBuilder.CLEAN_BUILD,null);
		return Status.OK_STATUS;
	}
	
	public static ISchedulingRule getRule(IProject proj)
	{
		return ResourcesPlugin.getWorkspace().getRuleFactory().createRule(ResourcesPlugin.getWorkspace().getRoot());
	}

}
