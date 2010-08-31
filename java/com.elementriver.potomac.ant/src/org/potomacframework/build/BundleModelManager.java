package org.potomacframework.build;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.HashMap;
import java.util.Iterator;

public class BundleModelManager {

	public static String getBundleXMLString(BundleModel model,boolean binVersion)
	{
		String newline = System.getProperty("line.separator");
		String xml = "";
		
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
	
	public static void saveModel(BundleModel model,File toFile) throws IOException
	{
		String xml = getBundleXMLString(model,true);		
		
		
	    Writer output = new BufferedWriter(new FileWriter(toFile));
	    try {
	      output.write( xml );
	    }
	    finally {
	      output.close();
	    }
	}
	
	private static String escapeXML(String toEscape)
	{
		toEscape = toEscape.replace("&","&amp;");
		toEscape = toEscape.replace("'","&apos;");
		toEscape = toEscape.replace("\"","&quot;");
		toEscape = toEscape.replace("<","&lt;");
		toEscape = toEscape.replace(">","&gt;");

		return toEscape;
	}
	
}
