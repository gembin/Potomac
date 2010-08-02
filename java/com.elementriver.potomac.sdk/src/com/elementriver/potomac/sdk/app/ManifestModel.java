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
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.ui.PlatformUI;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.elementriver.potomac.sdk.bundles.BundleModel;
import com.elementriver.potomac.sdk.bundles.BundleModelManager;

public class ManifestModel {
	
	public ArrayList<String> bundles = new ArrayList<String>();
	
	//a subset of bundles that includes the bundles that are loaded as RSLs
	public ArrayList<String> preloads = new ArrayList<String>();
	
	public ArrayList<String> enablesForFlags = new ArrayList<String>();
	
	public String templateID = "";
	
	public HashMap<String,String> templateProperties = new HashMap<String,String>();
	
	public String airBundlesURL = "";
	
	public Boolean airDisableCaching = false;

	public ManifestModel(IFile manifest)
	{		
		if (manifest == null || !manifest.exists())
		{
			return; 
		}
		
		File file = manifest.getLocation().toFile();
		
		try {
			SAXParser parser = SAXParserFactory.newInstance().newSAXParser();
			
			parser.parse(file,new DefaultHandler() {
				
				boolean inBundle = false;
				boolean preload = false;
				
				public void startElement(String uri, String localName, String name,
						Attributes attributes) throws SAXException {
					if (name.equals("bundle"))
					{
						inBundle = true;
						preload = Boolean.parseBoolean(attributes.getValue("rsl"));
						if (attributes.getValue("preload") != null)
							preload = Boolean.parseBoolean(attributes.getValue("preload"));
					}
					if (name.equals("application"))
					{
						templateID = attributes.getValue("template");
						String flags = attributes.getValue("enablesForFlags");
						if (flags != null)
						{
							String flagArray[] = flags.split(",");
							for (String flag : flagArray)
							{
								if (flag.trim().equals(""))
									continue;
								enablesForFlags.add(flag);
							}
						}
						
						airBundlesURL = attributes.getValue("airBundlesURL");
						if (airBundlesURL == null)
							airBundlesURL = "";
						
						airDisableCaching = Boolean.parseBoolean(attributes.getValue("airDisableCaching"));

					}
					if (name.equals("parameter"))
					{
						templateProperties.put(attributes.getValue("name"),attributes.getValue("value"));
					}
				}

				public void endElement(String uri, String localName, String name)
						throws SAXException {
					if (name.equals("bundle"))
					{
						inBundle = false;
						preload = false;
					}
				}

				public void characters(char[] ch, int start, int length)
						throws SAXException {
					if (inBundle)
					{
						String bundle = new String(ch,start,length).trim();
						bundles.add(bundle);
						if (preload)
						{
							preloads.add(bundle);
						}
					}
				}
								
			});
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (SAXException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
	}
	
	public void save(IFile manifest)
	{
		String newline = System.getProperty("line.separator");
		String xml = "";
		
		String enableFlagsString = "";
		for (String flag : enablesForFlags)
		{
			enableFlagsString += flag + ",";
		}
		if (enableFlagsString.endsWith(","))
			enableFlagsString = enableFlagsString.substring(0,enableFlagsString.length() -1);
		
		xml += "<application template='"+templateID +"' enablesForFlags='" + enableFlagsString + "' airBundlesURL='"+airBundlesURL+"' airDisableCaching='"+airDisableCaching+"'>" + newline;
		xml += "<templateData>" + newline;
		
		HashMap<String,String> parms = getTemplateParameters(templateID, bundles);
		
		if (parms != null)
		{
			for (String key : parms.keySet())
			{
				String val = "";
				if (templateProperties.get(key) != null)
					val = templateProperties.get(key);
				xml += "   <parameter name='"+key+"' type='" + parms.get(key) + "' value='"+val+"' />" + newline; 
			}
		}
		
		xml += "</templateData>" + newline;
		
		xml += "<bundles>" + newline;
		
		for (String bundle : bundles)
		{
			String preload = "false";
			if (preloads.contains(bundle))
				preload = "true";
			xml += "   <bundle preload='"+preload+"'>" + bundle + "</bundle>" + newline;
		}
		
		xml += "</bundles>" + newline;
		xml += "</application>";
		
		
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
	
	public HashMap<String,String> getTemplateParameters(String templateID,ArrayList<String> dependencies)
	{
		HashMap<String,String> parms = new HashMap<String,String>();
		HashMap<String,String> extension = null;
		
		for(String bundle : dependencies)
		{
			try {
				BundleModel model = BundleModelManager.getInstance().getModel(bundle);
				for (HashMap<String,String> ext : model.extensions)
				{
					if (ext.get("point").equals("Template") && ext.get("id").equals(templateID))
					{
						extension = ext;
					}
				}
			} catch (Exception e) {
				//ignore - likely due to an invalid or non-existing bundle
			}
		}
		
		if (extension == null) return null;
		
		if (extension.get("properties") != null)
		{
			String props[] = extension.get("properties").split(",");
			for (String prop :props)
			{
				String var[] = prop.split(":");
				if (var.length < 2) continue;
				parms.put(var[0], var[1]);
			}
		}
		
		return parms;
	}
}
