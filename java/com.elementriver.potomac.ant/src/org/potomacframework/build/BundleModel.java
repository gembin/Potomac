package org.potomacframework.build;

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
}
