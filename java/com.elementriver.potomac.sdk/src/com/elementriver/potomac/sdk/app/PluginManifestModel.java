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
import java.io.InputStream;
import java.io.UnsupportedEncodingException;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.ui.PlatformUI;

import com.elementriver.potomac.sdk.bundles.PluginBundleModelManager;
import com.elementriver.potomac.shared.BundleModelManager;
import com.elementriver.potomac.shared.ManifestModel;

public class PluginManifestModel extends ManifestModel {
	
	public PluginManifestModel(IFile manifest)
	{		
		if (manifest == null || !manifest.exists())
		{
			return; 
		}
		
		File file = manifest.getLocation().toFile();
		
		populate(file);
		
	}
	
	public void save(IFile manifest)
	{
		String xml = getManifestXML();		
		
		InputStream is = null;
		try {
			is = new ByteArrayInputStream(xml.getBytes("UTF-8"));
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			if (manifest.exists())
			{
				manifest.setContents(is, true,true, null);
			}
			else
			{
				manifest.create(is, true,null);
			}
		} catch (CoreException e) {
			e.printStackTrace();
			MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error Writing appManifest.xml", "Unable to write appManifest.xml.");
		}
		
	}

	@Override
	protected BundleModelManager getBundleModelManager()
	{
		return PluginBundleModelManager.getInstance();
	}
	

}
