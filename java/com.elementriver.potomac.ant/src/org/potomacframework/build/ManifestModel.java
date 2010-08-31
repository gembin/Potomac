package org.potomacframework.build;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

public class ManifestModel {
	
	public ArrayList<String> bundles = new ArrayList<String>();
	
	//a subset of bundles that includes the bundles that are loaded as RSLs
	public ArrayList<String> preloads = new ArrayList<String>();
	
	public ArrayList<String> enablesForFlags = new ArrayList<String>();
	
	public String templateID = "";
	
	public HashMap<String,String> templateProperties = new HashMap<String,String>();
	
	public String airBundlesURL = "";
	
	public Boolean airDisableCaching = false;

	public ManifestModel(File manifest)
	{		
		if (manifest == null || !manifest.exists())
		{
			return; 
		}
		
		try {
			SAXParser parser = SAXParserFactory.newInstance().newSAXParser();
			
			parser.parse(manifest,new DefaultHandler() {
				
				boolean inBundle = false;
				boolean preload = false;
				
				public void startElement(String uri, String localName, String name,
						Attributes attributes) throws SAXException {
					if (name.equals("bundle"))
					{
						inBundle = true;
						preload = Boolean.parseBoolean(attributes.getValue("rsl"));
						if (!preload)
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
			throw new RuntimeException(e);
		} catch (SAXException e) {
			throw new RuntimeException(e);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		
	}
	
	public HashMap<String,String> getTemplateParameters(String templateID,ArrayList<String> dependencies)
	{
		HashMap<String,String> parms = new HashMap<String,String>();
		HashMap<String,String> extension = null;
		
		for(String bundle : dependencies)
		{
			try {
				BundleModel model = BundleTask.getModel(bundle);
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
