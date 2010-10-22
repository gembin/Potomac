package com.elementriver.potomac.shared;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;

public class ExtensionsMetadataProcessor {
	
	public static String getAppInitializerSource(ManifestModel model,String projectRoot)
	{
		String newline = System.getProperty("line.separator");
		
		
		StringBuilder pInitContents = new StringBuilder();
		pInitContents.append("package potomac.derived {" + newline);
		pInitContents.append("   import flash.events.Event;" + newline);
		pInitContents.append("   import mx.core.FlexGlobals;" + newline);
		pInitContents.append("   import mx.events.FlexEvent;" + newline);
		pInitContents.append("   import potomac.core.Launcher;" + newline);
		pInitContents.append("   import potomac.core.LauncherManifest;" + newline);
		pInitContents.append("   import potomac.core.TemplateRunner;" + newline);
		pInitContents.append("   public class PotomacInitializer {" + newline);
		
		String bundles = "";
		String preloads = "";
		for (String bundle : model.bundles)
		{
			bundles += "\"" + bundle + "\",";
			
			if (model.preloads.contains(bundle))
				preloads += "\"" + bundle + "\",";
		}	
		
		if (bundles.endsWith(","))
			bundles = bundles.substring(0,bundles.length()-1);
		if (preloads.endsWith(","))
			preloads = preloads.substring(0,preloads.length()-1);
					
		pInitContents.append("      private var bundles:Array = ["+bundles+"];" + newline);
		pInitContents.append("      private var preloads:Array = ["+preloads+"];" + newline);
		
		pInitContents.append("      private var templateID:String = \""+model.templateID+"\";" + newline);
		pInitContents.append("      private var airBundlesURL:String = \""+model.airBundlesURL+"\";" + newline);
		pInitContents.append("      private var airDisableCaching:Boolean = "+model.airDisableCaching+";" + newline);
		
		String templateDataCode = "";
		HashMap<String,String> templatePropTypes = model.getTemplateParameters(model.templateID,model.bundles);
		for (String key : model.templateProperties.keySet())
		{
			String type = templatePropTypes.get(key);
			if (type.equals("image"))
			{
				if (model.templateProperties.get(key) != null && model.templateProperties.get(key).trim().length() > 0)
				{
					File file = new File(projectRoot + model.templateProperties.get(key));
					if (file != null && file.exists())
					{
						String path = file.getAbsolutePath();
						path = path.replace('\\','/');
						pInitContents.append("      [Embed(source=\""+path+"\")]" + newline);
						pInitContents.append("      private var templateProp_"+key+":Class;" + newline);
						templateDataCode += key + ":new templateProp_"+key+"(),";
					}
				}
			}
			else if (type.equals("boolean"))
			{
				String val = "false";
				if (model.templateProperties.get(key) != null && model.templateProperties.get(key).equals("true"))
					val = "true";
				templateDataCode += key + ":" + val + ",";
			}
			else
			{
				String val = "";
				if (model.templateProperties.get(key) != null)
					val = model.templateProperties.get(key);
				templateDataCode += key + ":\"" + val + "\",";
			}
		}
		if (templateDataCode.endsWith(","))
		{
			templateDataCode = templateDataCode.substring(0, templateDataCode.length() -1);
		}
		pInitContents.append("      private var templateData:Object = {"+templateDataCode+"};" + newline);

		String enableFlags = "";
		for (String flag : model.enablesForFlags)
		{
			enableFlags += "\"" + flag + "\",";
		}
		if (enableFlags.endsWith(","))
			enableFlags = enableFlags.substring(0,enableFlags.length() -1);
		
		pInitContents.append("      private var enablesForFlags:Array = ["+enableFlags+"];" + newline);
		pInitContents.append("      public function PotomacInitializer(){" + newline);
		pInitContents.append("         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.APPLICATION_COMPLETE,go);" + newline);
		pInitContents.append("         FlexGlobals.topLevelApplication.addEventListener(FlexEvent.INITIALIZE,init);" + newline);
		pInitContents.append("      }" + newline);
		pInitContents.append("      public function init(e:Event):void {" + newline);
		pInitContents.append("         Launcher.findPreloader();" + newline);
		pInitContents.append("      }" + newline);
		
		
		pInitContents.append("      public function go(e:Event):void {" + newline);
		pInitContents.append("         var runner:TemplateRunner = new TemplateRunner(templateID,templateData);" + newline);
		pInitContents.append("         var manifest:LauncherManifest = new LauncherManifest();" + newline);
		pInitContents.append("         manifest.bundles = bundles;" + newline);
		pInitContents.append("         manifest.preloads = preloads;" + newline);
		pInitContents.append("         manifest.airBundlesURL = airBundlesURL;" + newline);
		pInitContents.append("         manifest.disableAIRCaching = airDisableCaching;" + newline);
		pInitContents.append("         manifest.enablesForFlags = enablesForFlags;" + newline);
		pInitContents.append("         manifest.runner = runner;" + newline);
		pInitContents.append("         Launcher.launch(manifest);" + newline);
		pInitContents.append("      }" + newline);

		
		pInitContents.append("   }" + newline);
		pInitContents.append("}");


		return pInitContents.toString();
	}
	
	public static ArrayList<String> validateExtensionPoint(HashMap<String,String> attribs,ExtensionsHelper helper)
	{
		ArrayList<String> msgs = new ArrayList<String>();
		
		String id = (String) attribs.get("id");
		if (id == null || id.equals(""))
		{
			msgs.add("ExtensionPoint 'id' parameter not found.");
		}
		else
		{
			if (!isValidExtensionPointID(id))
			{
				msgs.add("ID '" + attribs.get(id) +"' is not a valid extension point id.");
			}
		}
		

		for(String key : attribs.keySet()) {     		
			
			if (isSpecialExtensionPointAttributes(key))
				continue;
			
			if (isReservedExtensionPointAttribute(key))
			{
				msgs.add("Attribute '" + key + "' is a reserved attribute name.");
				continue;
			}
			
		     String value = (String) attribs.get(key);
		     
		     if (isAutoAddedExtensionPointAttributes(key))
		     {
		    	 msgs.add("Attribute '" + key + "' is an automatically generated attribute.");
		    	 continue;
		     }
		     
		     if (value.startsWith("*"))
    		 {
		    	 value = value.substring(1);
    		 }

		     
		     if (value != null && !value.startsWith("choice:") && !value.startsWith("type:") && 
		    		 !value.equals("type") && !value.startsWith("class:") && 
		    		 !value.equals("class") && !value.startsWith("interface:") && 
		    		 !value.equals("interface") && !value.equals("string") && 
		    		 !value.equals("integer") && !value.equals("boolean") &&
		    		 !value.equals("asset") && !value.startsWith("asset:"))
		     {
		    	 msgs.add("Attribute '" + key + "' specifies an invalid datatype.  Valid datatypes are string, integer, boolean, type, class, interface, asset, or choice.");
		     }	
		     
		     //TODO: check we don't have an existing point with the same id
		     
		     //check any class: types are ok
		     if (value.startsWith("class:") || value.startsWith("interface:") || value.startsWith("type:"))
		     {
		    	 String className = "";
		    	 if (value.toLowerCase().startsWith("class:"))
		    	 {
		    		 className = value.substring(6);
		    	 }
		    	 else if (value.toLowerCase().startsWith("interface:"))
		    	 {
		    		 className = value.substring(10); 
		    	 }
		    	 else
		    	 {
		    		 className = value.substring(5);
		    	 }

		    	 PType def = helper.getType(className);
		    	 if (def == null)
		    	 {
		    		 msgs.add(className +" isn't a valid type.");
		    	 }
		    	 else 
		    	 {
			    	 if (value.toLowerCase().startsWith("class:") && !def.isClass())
			    	 {
			    		 //msgs.add(className + " isn't a valid class.");
			    	 }
			    	 else if (value.toLowerCase().startsWith("interface:") && !def.isInterface())
			    	 {
			    		msgs.add(className + " isn't a valid inteface.");
			    	 }
		    	 }
		     }			     
		}
		
		
		//Do type checking
		String type = attribs.get("type");
		if (type != null)
		{
		     if (type.startsWith("*"))
			 {
		    	 type = type.substring(1);
			 }

	    	 PType def = helper.getType(type);
	    	 if (def == null)
	    	 {
	    		 msgs.add(type +" isn't a valid type.");
	    	 }
	     }	

		
    	 //Do access checking
		String access = attribs.get("access");
		if (access != null)
		{
		     if (access.startsWith("*"))
			 {
		    	 access = access.substring(1);
			 }
		     String accessTypes[] = access.split(",");
		     for (String choice : accessTypes)
		     {
		    	 if (!choice.equals("private") && !choice.equals("protected") && !choice.equals("public") && !choice.equals("internal"))
		    	 {
		    		 msgs.add("Special attribute 'access' must be a comma delimited string with any of the following values: public,protected,private,internal.");
		    		 break;
		    	 }
		     }
		}
    	   	 
    	 
    	 //Do declaredOn checking
		String declaredOn = attribs.get("declaredOn");
		if (declaredOn != null)
		{
			if (declaredOn.startsWith("*"))
			{
				declaredOn = declaredOn.substring(1);
			}
		     String choices[] = declaredOn.split(",");
		     for (String choice : choices)
		     {
		    	 if (!choice.equals("classes") && !choice.equals("methods") && !choice.equals("variables") && !choice.equals("constructors"))
		    	 {
		    		 msgs.add("Special attribute 'declaredOn' must be a comma delimited string with any of the following values: classes,constructors,methods,variables.");
		    		 break;
		    	 }
		     }
		}
			
		//Do argumentsAsAttributes checking
		String argsAsAttribs = attribs.get("argumentsAsAttributes");
		if (argsAsAttribs != null)
		{
			if (argsAsAttribs.startsWith("*"))
			{
				argsAsAttribs = argsAsAttribs.substring(1);
			}
			if (argsAsAttribs.equalsIgnoreCase("true"))
			{
				if (declaredOn != null && !(declaredOn.contains("methods") || declaredOn.contains("constructors") || declaredOn.contains("variables")))
				{
					msgs.add("'argumentsAsAttributes' may only be specified when 'declaredOn' includes constructors, methods, or variables.");
				}
			}			
		}
		
		
		return msgs;
	}

	
	
	
	public static ArrayList<String> validateExtension(HashMap<String,String> ext, HashMap<String,String> extPt, PType containingType, PDefinition declaringDefinition,ExtensionsHelper helper, BundleModel bundleModel)
	{
		ArrayList<String> msgs = new ArrayList<String>();
		

		for (String key : extPt.keySet()) 
		{					
			if (key.equals("bundle") || key.equals("declaredBy") || key.equals("id") ||
					key.equals("type") || key.equals("declaredOn") || key.equals("access") )
			{
				continue;
			}

			String datatype = extPt.get(key);
			boolean reqd = datatype.startsWith("*");
			if (reqd)
				datatype = datatype.substring(1);
			
			String value = ext.get(key);
			
			if (value != null && !value.trim().equals(""))
			{
				
				//check datatypes
				if (datatype.equalsIgnoreCase("integer"))
				{
					try {
						Integer.parseInt(value);
					} catch (NumberFormatException e) {
						msgs.add("Attribute '" + key + "' must be a valid integer.");
					}
				}
				else if (datatype.equalsIgnoreCase("boolean"))
				{
					if (!value.equalsIgnoreCase("true") && !value.equalsIgnoreCase("false"))
					{
						msgs.add("Attribute '" + key + "' must be either true or false.");
					}
				}
				else if (datatype.toLowerCase().startsWith("class"))
				{
					String classType = "";
					if (datatype.length() > 6)
						classType = datatype.substring(6);
					
					PType def = helper.getType(value);
					if (def == null || def.isInterface())
					{
						msgs.add("Attribute + '" + key + "' must be a fully qualified class name.");
					}
					else
					{
						PType valueDef = helper.getType(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("interface"))
				{
					String classType = "";
					if (datatype.length() > 10)
						classType = datatype.substring(10);
					
					PType def = helper.getType(value);
					if (def == null || !def.isInterface())
					{
						msgs.add("Attribute + '" + key + "' must be a fully qualified interface name.");
					}
					else
					{
						PType valueDef = helper.getType(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("type"))
				{
					String classType = "";
					if (datatype.length() > 5)
						classType = datatype.substring(5);
					
					PType def = helper.getType(value);
					if (def == null)
					{
						msgs.add("Attribute '" + key + "' must be a fully qualified type name.");
					}
					else
					{
						PType valueDef = helper.getType(value);
						if (valueDef == null || ((!classType.equals("")) && !valueDef.isInstanceOf(classType)))
						{
							msgs.add("Attribute '" + key + "' must be a fully qualified subclass of " + classType +".");
						}
					}
				}
				else if (datatype.startsWith("choice"))
				{
					String choicesString = "";
					if (datatype.length() > 7)
						choicesString = datatype.substring(7);
					
					String choices[] = choicesString.split(",");
					boolean found = false;
					for (String choice : choices)
					{
						if (choice.equals(value))
						{
							found = true;
							break;
						}
					}
					if (!found)
					{
						msgs.add("Attribute '" + key + "' must be one of the following values :" + choicesString);
					}
				}
				else if (datatype.startsWith("asset"))
				{
					
					boolean addAsset = true;
					
					String assetPath = helper.getProjectRoot().getAbsolutePath() +"/" + value;

					File asset = new File(assetPath);
					if (!asset.exists())
					{
						assetPath = helper.getProjectRoot().getAbsolutePath() +"/extensionAssets/" + value;
						asset = new File(assetPath);
						if (asset.exists())
						{
							ext.put(key,"extensionAssets/" + value);
						}
					}

					if (!asset.exists())
					{
						msgs.add("Asset '" + value + "' not found.");
						addAsset = false;
					}
					
					String assetTypes = "";
					if (datatype.length() > 6)
						assetTypes = datatype.substring(6);
					
					String types[] = assetTypes.split(",");
					boolean found = false;
					for (String type : types)
					{
						if (value.toLowerCase().endsWith("." + type))
						{
							found = true;
							break;
						}
					}
					if (!found)
					{
						msgs.add("Attribute '" + key + "' must be an asset of type: " + assetTypes);
						addAsset = false;
					}
					
					if (addAsset)
						bundleModel.extensionAssets.add(asset.getAbsolutePath());
				}
			}
			else if (reqd)
			{
				msgs.add("Missing required attribute '" + key + "'.");
			}					
		}
		
	
		//Setup the data necessary to check attrib names when argumentsAsAttributes is true
		ArrayList<PVariable> vars = new ArrayList<PVariable>();
		String argsAsAttribsVal = extPt.get("argumentsAsAttributes");
		boolean argsAsAttribs = (argsAsAttribsVal != null && argsAsAttribsVal.equalsIgnoreCase("true"));
		if (argsAsAttribs)
		{
			if (declaringDefinition instanceof PFunction)
			{
				vars.addAll(((PFunction)declaringDefinition).getArguments());
			}
			else if (declaringDefinition instanceof PVariable)
			{
				vars.add((PVariable) declaringDefinition);
			}
			else
			{
				argsAsAttribs = false;
			}				
		}
				
		//look for extra attribs
		for (String key : ext.keySet()){
			if (key.equals("point") || key.equals("enablesFor")) {
				continue;
			}
			
			if (!isValidExtensionAttribute(key))
			{
				msgs.add("Attribute '" + key + "' is not a valid attribute name.");
				continue;
			}
			
			if (!extPt.containsKey(key))
			{
				if (argsAsAttribs)
				{
					boolean foundName = false;
					//check that attrib is an arg name				
					for (PVariable var : vars)
					{
						if (var.getName().equals(key))
						{
							foundName = true;
							break;
						}
					}	
					if (!foundName)
					{
						msgs.add("Invalid attribute '" + key + "'.");
					}
				}
				else					
				{
					msgs.add("Invalid attribute '" + key + "'.");
				}
			}
		}
	
		//check special type requirements
		if (extPt.containsKey("type"))
		{
			String type = extPt.get("type");
			if (type.startsWith("*"))
				type = type.substring(1);

			if (!containingType.isInstanceOf(type))
			{
				msgs.add("This tag must be declared on classes that extend " + type + ".");
			}
		}
		
		//check special access requirements
		if (extPt.containsKey("access"))
		{
			String accessTypes = extPt.get("access");
			if (accessTypes.startsWith("*"))
				accessTypes = accessTypes.substring(1);
			
			String access = declaringDefinition.getNamespace();
			if (!accessTypes.contains(access))
			{
				msgs.add("This tag must be declared on definitions with one of the following access modifiers: " + accessTypes +".");
			}
		}
				
		//check special declaredOn requirements
		if (extPt.containsKey("declaredOn"))
		{
			String declaredOn = extPt.get("declaredOn");
			if (declaredOn.startsWith("*"))
			{
				declaredOn = declaredOn.substring(1);
			}

			String classification = "";
			if (declaringDefinition instanceof PFunction)
			{
				if (((PFunction)declaringDefinition).isConstructor())
				{
					classification = "constructors";
				}
				else
				{
					classification = "methods";
				}
			} else if (declaringDefinition instanceof PType && ((PType)declaringDefinition).isClass())
			{
				classification = "classes";
			} else if (declaringDefinition instanceof PVariable)
			{
				classification = "variables";
			}

			if (!declaredOn.contains(classification))
			{
				msgs.add("This tag must be declared on one of the following: " + declaredOn +".");
			}			
		}
		
		if (extPt.containsKey("idRequired"))
		{
			if (extPt.get("idRequired").equals("true"))
			{
				if (!ext.containsKey("id"))
				{
					msgs.add("Missing required attribute 'id'.");
				}
			}
		}

		return msgs;
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	public static boolean isValidExtensionPointID(String id)
	{		
		return !contains(new String[]{"ExtensionPoint","Extension"},id);
	}
	
	public static boolean isValidExtensionAttribute(String attribute)
	{
		return !contains(getAutoAddedExtensionAttributes(),attribute);		
	}
	
	public static boolean isSpecialExtensionPointAttributes(String attribute)
	{
		//these are essentially the user entered attribs
		return contains(new String[]{"id","type","declaredOn","declaredBy","access","functionSignature","variableType","argumentsAsAttributes","idRequired","rslRequired","preloadRequired"},attribute);
	}
	
	public static boolean isAutoAddedExtensionPointAttributes(String attribute)
	{
		return contains(new String[]{"bundle","declaredBy","codeStart","codeEnd"},attribute);
	}
	
	public static String[] getAutoAddedExtensionAttributes()
	{
		return new String[]{"bundle","class","function","functionSignature","variable","variableType","codeStart","codeEnd"};
	}
	
	
	private static boolean contains(String array[],String value)
	{
		for (int i = 0; i < array.length; i++) {
			if (array[i].equals(value))
			{
				return true;
			}
		}
		return false;
	}

	public static boolean isReservedExtensionPointAttribute(String attribute) {
		return contains(new String[]{"enable","enablesFor","roles","flags","mode","context"},attribute);
	}
}
