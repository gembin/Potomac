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

import java.util.ArrayList;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.Platform;

import com.elementriver.sourcemate.metadata.SourceMate;

public class IgnoredMetadata {
	private static final String IGNORED_METADATA_PREF = "IgnoredMetadataPref";
	private static final String DEFAULT_IGNORED_METADATA = "After,AfterClass,Alternative,ArrayElementType,Before,BeforeClass,Bindable,DataPoint,DefaultProperty,Deprecated,Effect,Embed,Event,Exclude,ExcludeClass,Frame,HostComponent,IconFile,Ignore,Inspectable,InstanceType,Mixin,NonCommittingChangeEvent,PercentProxy,RemoteClass,ResourceBundle,RichTextContent,RunWith,SWF,SkinPart,SkinState,Style,Suite,Test,Theory,Transient";
	
	
	private static ArrayList<String> tags = null;

	public static ArrayList<String> getTags()
	{
		if (tags == null)
		{
			Activator.getDefault().getPreferenceStore().setDefault(IGNORED_METADATA_PREF, DEFAULT_IGNORED_METADATA);
			
			String prefValue = Activator.getDefault().getPreferenceStore().getString(IGNORED_METADATA_PREF);
			
			tags = new ArrayList<String>();
			
			String prefs[] = prefValue.split(",");
			for (String pref : prefs)
			{
				if (pref.trim().length() == 0)
					continue;
				tags.add(pref);
			}
		}
		
		return tags;		
	}
	
	public static ArrayList<String> getDefaults()
	{
		ArrayList<String> defaults = new ArrayList<String>();
		
		String prefs[] = DEFAULT_IGNORED_METADATA.split(",");
		for (String pref : prefs)
		{
			if (pref.trim().length() == 0)
				continue;
			defaults.add(pref);
		}
		return defaults;
	}
	
	public static boolean isIgnored(String tag)
	{
		return getTags().contains(tag);
	}
	
	public static void saveTags(ArrayList<String> tags)
	{
		IgnoredMetadata.tags = tags;
		
		String prefValue = "";
		
		for (String tag : tags)
		{
			prefValue += tag + ",";
		}
		if (prefValue.endsWith(","))
			prefValue = prefValue.substring(0,prefValue.length()-1);
		
		Activator.getDefault().getPreferenceStore().setValue(IGNORED_METADATA_PREF, prefValue);
	}
	
	public static boolean isSourceMateValidating(IProject project)
	{
		if (Platform.getBundle("com.elementriver.sourcemate") != null)
		{
			return SourceMate.isSourceMateValidatingMetadata(project);
		}
		
		return false;
	}

}
