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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.PlatformUI;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.elementriver.potomac.sdk.Potomac;

public class BundleModelManager {

	private static BundleModelManager instance;
	
	private HashMap<String,BundleModel> models = new HashMap<String,BundleModel>();
	private ArrayList<Listener> listeners = new ArrayList<Listener>();
		
	private BundleModelManager()
	{		
	}
	
	public static BundleModelManager getInstance()
	{
		if (instance == null)
		{
			instance = new BundleModelManager();
		}
		return instance;
	}
	
	public BundleModel getModel(String id)
	{
		if (!models.containsKey(id))
		{
			loadModel(id);
			//if it still isnt loaded (error) just return an empty model
			if (!models.containsKey(id))
				return new BundleModel();
		}
		return models.get(id);
	}
	
	public void clearModelCache(String id)
	{
		if (models.containsKey(id))
		{
			models.remove(id);
		}
	}
	
	public void addModel(BundleModel model)
	{
		models.put(model.id, model);
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
	
	public HashMap getExtensionPoint(String point)
	{		
		ArrayList<String> bundles;
		try {
			bundles = Potomac.getBundles();
		} catch (CoreException e) {
			throw new RuntimeException(e);
		}
		for (String bundle : bundles) {
			BundleModel model = getModel(bundle);
			for (HashMap extPt : model.extensionPoints) {
				if (extPt.get("id").equals(point))
				{
					return extPt;
				}
			}
		}
		return null;
	}
	
	public ArrayList<String> getAllExtensionPointIDs(ArrayList<String> bundles)
	{
		ArrayList<String> pts = new ArrayList<String>();

		for (String bundle : bundles) {

			BundleModel model = getModel(bundle);
			if (model != null)
			{
				for (HashMap extPt : model.extensionPoints) {
					pts.add((String) extPt.get("id"));
				}
			}
		}	
		return pts;
	}
	
	public void createAndSaveModel(String id)
	{
		BundleModel model = new BundleModel();
		model.id = id;
		model.version = "";
		model.name = "";
		model.activator = "";
		models.put(id,model);
		
		saveModel(id,false);		
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
	
	public String getBundleXMLString(String id,boolean binVersion)
	{
		String newline = System.getProperty("line.separator");
		String xml = "";
		BundleModel model = getModel(id);
		
		xml += "<bundle id='" + model.id + "' version='" + model.version + "' name='" + escapeXML(model.name) + "' activator='" + model.activator + "'>" + newline;
		
		xml += "<requiredBundles>" + newline;
		for (Iterator iterator = model.dependencies.iterator(); iterator.hasNext();) {
			String depend = (String) iterator.next();
			xml += "   <bundle>" + depend + "</bundle>" + newline;
		}		
		xml += "</requiredBundles>" + newline;

		if (binVersion)
		{
			xml += "<extensionPoints>" + newline;
			
			for (HashMap<String,String> extPt : model.extensionPoints)
			{
				xml += "   <extensionPoint id='" + extPt.get("id") + "' declaredBy='" + extPt.get("declaredBy") + "' ";
				
				for (String key : extPt.keySet()) {
					if (key.equals("id") || key.equals("declaredBy") || key.equals("bundle") )
					{
						continue;
					}				
					xml += key + "='" + extPt.get(key) + "' ";
				}			
				xml += "bundle='" + model.id + "'/>" + newline;
			}		
			xml += "</extensionPoints>" + newline;
			
			
			xml += "<extensions>" + newline;
			for (HashMap<String,String> ext : model.extensions)
			{
				xml += "   <extension point='" + ext.get("point") + "' class='" + ext.get("class") + "' ";
				
				for (String key : ext.keySet()) {
					if (key.equals("class") || key.equals("bundle") || key.equals("point"))
					{
						continue;
					}				
					xml += key + "='" + escapeXML(ext.get(key)) + "' ";
				}			
				xml += "bundle='" + model.id + "'/>" + newline;
			}		
			xml += "</extensions>" + newline;
		}
			
		xml += "</bundle>" + newline;
		
		return xml;
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
	
	private void loadModel(String id)
	{
		
		//First get the main settings from the root bundle.xml
		File file = Potomac.getBundleXML(id,false);
		
		if (!file.exists())
		{
			throw new RuntimeException(id + " does not contain a bundle.xml!");
		}
		
		final BundleModel model = new BundleModel();
		model.id = id;
		
		try {
			SAXParser parser = SAXParserFactory.newInstance().newSAXParser();
			
			parser.parse(file,new DefaultHandler() {
				
				boolean inDependencies = false;
				boolean inBundle = false;
				
				public void startElement(String uri, String localName, String name,
						Attributes attributes) throws SAXException {
					if (name.equals("bundle"))
					{
						if (!inDependencies)
						{
							model.version = attributes.getValue("version");
							model.name = attributes.getValue("name");
							model.activator = attributes.getValue("activator");
						}
						else
						{
							inBundle = true;
						}
					}
					if (name.equals("requiredBundles"))
					{
						inDependencies = true;
					}
					if (name.equals("extensionPoint"))
					{
						HashMap extPt = new HashMap();
						for (int i = 0; i < attributes.getLength(); i++) {
							extPt.put(attributes.getQName(i),attributes.getValue(i));
						}
						model.extensionPoints.add(extPt);
					}
					if (name.equals("extension"))
					{
						HashMap ext = new HashMap();
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
					if (inDependencies && inBundle)
					{
						model.dependencies.add(new String(ch,start,length).trim());
					}
				}
								
			});
		} catch (ParserConfigurationException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		
		//now get the extensions/pts from the bin/bundle.xml
		file = Potomac.getBundleXML(id,true);
		
		if (file.exists())
		{
			
			try {
				SAXParser parser = SAXParserFactory.newInstance().newSAXParser();
				
				parser.parse(file,new DefaultHandler() {

					public void startElement(String uri, String localName, String name,
							Attributes attributes) throws SAXException {
						
						if (name.equals("extensionPoint"))
						{
							HashMap extPt = new HashMap();
							for (int i = 0; i < attributes.getLength(); i++) {
								extPt.put(attributes.getQName(i),attributes.getValue(i));
							}
							model.extensionPoints.add(extPt);
						}
						if (name.equals("extension"))
						{
							HashMap ext = new HashMap();
							for (int i = 0; i < attributes.getLength(); i++) {
								ext.put(attributes.getQName(i),attributes.getValue(i));
							}
							model.extensions.add(ext);						
						}
					}								
				});
			} catch (ParserConfigurationException e) {
				e.printStackTrace();
			} catch (SAXException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		
		models.put(id,model);		
	}
	
	private String escapeXML(String toEscape)
	{
		toEscape = toEscape.replace("&","&amp;");
		toEscape = toEscape.replace("'","&apos;");
		toEscape = toEscape.replace("\"","&quot;");
		toEscape = toEscape.replace("<","&lt;");
		toEscape = toEscape.replace(">","&gt;");

		return toEscape;
	}

}
