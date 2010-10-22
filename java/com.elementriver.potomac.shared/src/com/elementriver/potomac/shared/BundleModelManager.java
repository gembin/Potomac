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
package com.elementriver.potomac.shared;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

public abstract class BundleModelManager {


	private HashMap<String,BundleModel> models = new HashMap<String,BundleModel>();

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

	public abstract File getBundleXMLFile(String id,boolean binVersion);
	
	public abstract void fireBundleExtensionChangeEvent(String id);
	
	public abstract ArrayList<String> getAllBundles();
	
	public HashMap getExtensionPoint(String point)
	{		
		ArrayList<String> bundles = getAllBundles();

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
	
	public abstract void saveModel(String id,boolean binVersion);
	
	public String getBundleXMLString(String id,boolean binVersion)
	{
		String newline = System.getProperty("line.separator");
		String xml = "";
		BundleModel model = getModel(id);
		
		String idAttribute = "";
		if (binVersion)
			idAttribute = "id='"+id+"'";
		
		xml += "<bundle "+idAttribute+" version='" + model.version + "' name='" + escapeXML(model.name) + "' activator='" + model.activator + "'>" + newline;
		
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
	

	
	private void loadModel(String id)
	{
		
		//First get the main settings from the root bundle.xml
		File file = getBundleXMLFile(id, false);
		
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
		file = getBundleXMLFile(id, true);
		
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
