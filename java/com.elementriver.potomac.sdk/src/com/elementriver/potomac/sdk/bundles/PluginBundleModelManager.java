package com.elementriver.potomac.sdk.bundles;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Iterator;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.PlatformUI;

import com.elementriver.potomac.sdk.Potomac;
import com.elementriver.potomac.shared.BundleModelManager;

public class PluginBundleModelManager extends BundleModelManager
{
	
	private static PluginBundleModelManager instance;
	
	private ArrayList<Listener> listeners = new ArrayList<Listener>();
	
	
	public static PluginBundleModelManager getInstance()
	{
		if (instance == null)
		{
			instance = new PluginBundleModelManager();
		}
		return instance;
	}
	
	public void addListener(Listener listener)
	{
		listeners.add(listener);
	}
	
	public void removeListener(Listener listener)
	{
		listeners.remove(listener);
	}

	public void fireBundleExtensionChangeEvent(String id)
	{
		Event e = new Event();
		e.data = id;
		for (Iterator iterator = listeners.iterator(); iterator.hasNext();) {
			Listener listener = (Listener) iterator.next();
			listener.handleEvent(e);
		}
	}
	
	public File getBundleXMLFile(String id,boolean binVersion)
	{
		return Potomac.getBundleXML(id,false);
	}
	
	public ArrayList<String> getAllBundles()
	{
		try
		{
			return Potomac.getBundles();
		} catch (CoreException e)
		{
			throw new RuntimeException(e);
		}
	}
	
	public void saveModel(String id,boolean binVersion)
	{
		String xml = getBundleXMLString(id,binVersion);		
		
		InputStream is = null;
		try {
			is = new ByteArrayInputStream(xml.getBytes("UTF-8"));
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
		}
		
	
		IFile bundlexml = null;
		
		if (binVersion)
		{
			bundlexml = ResourcesPlugin.getWorkspace().getRoot().getProject(id).getFile(Potomac.getOutputDirectory(ResourcesPlugin.getWorkspace().getRoot().getProject(id))+"/bundle.xml");
		}
		else
		{
			bundlexml = ResourcesPlugin.getWorkspace().getRoot().getProject(id).getFile("bundle.xml");
		}
		
		try {
			if (bundlexml.exists())
			{
				bundlexml.setContents(is, true,true, null);
			}
			else
			{
				bundlexml.create(is, true,null);
			}
			bundlexml.setDerived(binVersion);
		} catch (CoreException e) {
			e.printStackTrace();
			MessageDialog.openError(PlatformUI.getWorkbench().getActiveWorkbenchWindow().getShell(), "Error Writing Bundle.xml", "Unable to write " + id + "/bundle.xml.  " + e.getMessage());
		}
	}
	
	/**
	 * This is a method that checks the root bundle.xml to see if it contains ext or ext pt data
	 * this is just used in the bundle builder to check and see if this data exists and therefore needs to 
	 * be deleted as the new approach is to only include ext and ext pts in the bin/bundle.xml.  
	 * Eventually we should remove this code as only older projects (prior to the approach change) should have 
	 * this data.
	 */
	public boolean modelHasOlderData(String id)
	{
		
		IFile bundlexml = ResourcesPlugin.getWorkspace().getRoot().getProject(id).getFile("bundle.xml");
		
		if (!bundlexml.exists())
			return false;

		String xmlText = "";
		try {
			xmlText = getText(bundlexml);
		} catch (CoreException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		if (xmlText.indexOf("<extensions>") > -1 || xmlText.indexOf("<extensionPoints>") > 0)
			return true;
		
		return false;
	}
	
	private static String getText(IFile file) throws CoreException, IOException
	{
		InputStream in = file.getContents();
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		byte[] buf = new byte[1024];
		int read = in.read(buf);
		while (read > 0) {
			out.write(buf, 0, read);
			read = in.read(buf);
		}
		return out.toString(file.getCharset());
	}

}
