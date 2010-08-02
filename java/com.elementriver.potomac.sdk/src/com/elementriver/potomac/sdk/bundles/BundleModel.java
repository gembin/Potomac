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

import java.util.ArrayList;
import java.util.HashMap;

public class BundleModel {
	
	public String id;	
	public String version;	
	public String name;
	public String activator;
	public ArrayList<String> dependencies = new ArrayList<String>();
	public ArrayList<HashMap<String,String>> extensions = new ArrayList<HashMap<String,String>>();
	public ArrayList<HashMap<String,String>> extensionPoints = new ArrayList<HashMap<String,String>>();

	//stores the extensions assets between builds
	//this is only a temporary list that helps us know if we need to rebuild
	//the assets swf if the list of assets changes
	public ArrayList<String> extensionAssets = new ArrayList<String>();
	
	//Used by the bundle builder to see if the assets.swf needs to be rebuilt
	public boolean dirty = false;
	
	public HashMap<String,String> getExtensionPointDetails(String point,String attribute)
	{
		for (HashMap<String,String> ext : extensions)
		{
			if (ext.get("point").equals("ExtensionPointDetails") && ext.get("id") != null && ext.get("id").equals(point))
			{
				if (attribute == null && ext.get("attribute") == null)
					return ext;
				
				if (attribute.equals(ext.get("attribute")))
					return ext;
			}
		}
		
		return null;
	}
}
