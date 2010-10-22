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
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;

import org.eclipse.core.resources.IProject;

import com.elementriver.potomac.sdk.bundles.PluginBundleModelManager;
import com.elementriver.potomac.shared.BundleModel;
import com.elementriver.sourcemate.metadata.AttributeModel;
import com.elementriver.sourcemate.metadata.IMetadataProvider;
import com.elementriver.sourcemate.metadata.MetadataModel;

public class SourceMateMetadataProvider implements IMetadataProvider {

	public List<MetadataModel> getMetadata(IProject project) {
		BundleModel bundle = null;
		
		try {
			bundle = PluginBundleModelManager.getInstance().getModel(project.getName());
		} catch (Exception e) {
			//ignore
		}
		
		ArrayList<MetadataModel> metadatas = new ArrayList<MetadataModel>();
		if (bundle == null)
			return metadatas;
		
		MetadataModel extPtTag = new MetadataModel();
		extPtTag.name = "ExtensionPoint";
		extPtTag.description = "(Potomac) Declares an extension point/custom metadata tag";
		extPtTag.onVariables = false;
		extPtTag.onFunctions = false;
		extPtTag.onGetters = false;
		extPtTag.onSetters = false;
		extPtTag.validateTag = false;
		AttributeModel attr = new AttributeModel();
		attr.name = "id";
		attr.required = true;
		attr.description = "Name of new metadata tag";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "type";
		attr.datatype = AttributeModel.AS_TYPE;
		attr.insertedByProposal = false;
		attr.description = "Requires all declarations on classes of the specified type (must be fully qualified)";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "declaredOn";
		attr.datatype = AttributeModel.CHOICE;
		attr.choices = new String[]{"classes","methods","variables","constructors"};
		attr.insertedByProposal = false;
		attr.description = "Limits where the tag may be declared (valid values are 'classes','methods','variables','constructors')";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "access";
		attr.datatype = AttributeModel.CHOICE;
		attr.choices = new String[]{"public","protected","private"};
		attr.insertedByProposal = false;
		attr.description = "Requires tag declarations on elements of the specified access ('public','protected','private')";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "idRequired";
		attr.datatype = AttributeModel.BOOLEAN;
		attr.insertedByProposal = false;
		attr.description = "If true, requires all tag declarations to include an id attribute";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "preloadRequired";
		attr.datatype = AttributeModel.BOOLEAN;
		attr.insertedByProposal = false;
		attr.description = "If true, requires all bundles using this tag to be preloaded";
		extPtTag.attributes.add(attr);
		attr = new AttributeModel();
		attr.name = "argumentsAsAttributes";
		attr.datatype = AttributeModel.BOOLEAN;
		attr.insertedByProposal = false;
		attr.description = "If true, allows dynamic tag attributes with the same name as the function's arguments";
		extPtTag.attributes.add(attr);
		metadatas.add(extPtTag);
		
		for (HashMap<String,String> extPt : bundle.extensionPoints)
		{
			metadatas.add(convertExtensionPointToMetadataModel(extPt,bundle));
		}
		
		for (String requiredBundle : bundle.dependencies)
		{
			bundle = PluginBundleModelManager.getInstance().getModel(requiredBundle);
			
			for (HashMap<String,String> extPt : bundle.extensionPoints)
			{
				metadatas.add(convertExtensionPointToMetadataModel(extPt,bundle));
			}
		}
		
		return metadatas;
	}
	
	private MetadataModel convertExtensionPointToMetadataModel(HashMap<String,String> extPt,BundleModel bundle)
	{
		MetadataModel metadata = new MetadataModel();
		metadata.name = extPt.get("id");
		metadata.validateTag = false;
		
		HashMap<String,String> detail = bundle.getExtensionPointDetails(metadata.name, null);
		if (detail != null)
			metadata.description = "(Potomac) "+detail.get("description");

		metadata.onGetters = false;
		metadata.onSetters = false;
		
		String type = extPt.get("type");
		if (type != null)
			metadata.validOnType = type;
		
		//We're making a (sort of bad) assumption that 'type' and 'variableType' are only valid exclusive of one another
		type = extPt.get("variableType");
		if (type != null)
			metadata.validOnType = type;
		
		String declaredOn = extPt.get("declaredOn");
		if (declaredOn != null)
		{
			if (declaredOn.startsWith("*"))
			{
				declaredOn = declaredOn.substring(1);
			}
			metadata.onClasses = (declaredOn.indexOf("classes") != -1);
			metadata.onVariables = (declaredOn.indexOf("variables") != -1);
			metadata.onFunctions = (declaredOn.indexOf("methods") != -1 || declaredOn.indexOf("constructors") != -1);
		}
		
		
		metadata.onInternal = false;
		String access = extPt.get("access");
		if (access != null)
		{
			metadata.onPublic = (access.indexOf("public") != -1);
			metadata.onPrivate = (access.indexOf("private") != -1);
			metadata.onProtected = (access.indexOf("protected") != -1);
		}
		
		String argsAsAttribs = extPt.get("argumentsAsAttributes");
		if (argsAsAttribs != null && argsAsAttribs.equalsIgnoreCase("true"))
			metadata.argumentsAsAttributes = true;
		

		
		ArrayList<AttributeModel> attribs = new ArrayList<AttributeModel>();
		
		
		String idReq = extPt.get("idRequired");
		if (idReq != null && idReq.equals("true"))
		{
			AttributeModel attr = new AttributeModel();
			attr.name = "id";
			attr.required = true;
			
			detail = bundle.getExtensionPointDetails(metadata.name, "id");
			if (detail != null)
			{
				attr.description = detail.get("description");
				if (detail.get("order") != null)
					attr.temp = Integer.parseInt(detail.get("order"));
				if (detail.get("common") != null && detail.get("common").equals("false"))
					attr.insertedByProposal = false;
			}
			else
			{
				attr.description = "Unique identifier";
				attr.temp = 0;
			}
			
			attribs.add(attr);
		}

		for (String key : extPt.keySet())
		{
			if (key.equals("bundle") || key.equals("declaredBy") || key.equals("id") || key.equals("argumentsAsAttributes") ||
					key.equals("type") || key.equals("declaredOn") || key.equals("access") || key.equals("variableType") ||
					key.equals("idRequired") || key.equals("rslRequired") || key.equals("preloadRequired"))
			{
				continue;
			}
			
			AttributeModel attr = new AttributeModel();
			
			attr.name = key;
			
			detail = bundle.getExtensionPointDetails(metadata.name, key);
			if (detail != null)
			{
				attr.description = detail.get("description");
				if (detail.get("order") != null)
					attr.temp = Integer.parseInt(detail.get("order"));
				if (detail.get("common") != null && detail.get("common").equals("false"))
					attr.insertedByProposal = false;
				if (detail.get("defaultValue") != null)
					attr.defaultValue = detail.get("defaultValue");
			}
			
			String datatype = extPt.get(key);
			if (datatype.startsWith("*"))
			{
				attr.required = true;
				attr.insertedByProposal = true;
				datatype = datatype.substring(1);
			}
			
			
			if (datatype.equalsIgnoreCase("string"))
			{
				attr.datatype = AttributeModel.STRING;
			}
			else if (datatype.equalsIgnoreCase("integer"))
			{
				attr.datatype = AttributeModel.INTEGER;
			}
			else if (datatype.equalsIgnoreCase("boolean"))
			{
				attr.datatype = AttributeModel.BOOLEAN;
			}
			else if (datatype.startsWith("choice"))
			{
				attr.datatype = AttributeModel.CHOICE;
				String choice = datatype.substring(datatype.indexOf(":")+1);
				String choices[] = choice.split(",");
				attr.choices = choices;
			}
			else if (datatype.startsWith("class") || datatype.startsWith("interface") || datatype.startsWith("type"))
			{
				attr.datatype = AttributeModel.AS_TYPE;
				if (datatype.indexOf(":") != -1)
				{
					String asType = datatype.substring(datatype.indexOf(":")+1);
					attr.asType = asType;
				}
			}
			else if (datatype.startsWith("asset"))
			{
				attr.datatype = AttributeModel.FILE;
				if (datatype.indexOf(":") != -1)
				{
					String ext = datatype.substring(datatype.indexOf(":")+1);
					String exts[] = ext.split(",");
					attr.validFileExtensions = exts;
				}
			}
			else
			{
				continue; //if we don't recognize the datatype skip it
			}
						
			
			attribs.add(attr);
		}
		
		//sort
		Collections.sort(attribs,new Comparator<AttributeModel>() {
			public int compare(AttributeModel o1, AttributeModel o2) {
				return o1.temp - o2.temp;
			}
		});
		
		metadata.attributes.addAll(attribs);
		
		return metadata;
	}

}
