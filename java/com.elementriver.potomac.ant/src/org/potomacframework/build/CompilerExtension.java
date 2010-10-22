package org.potomacframework.build;

import java.io.File;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;

import org.potomacframework.build.extensionproc.AntExtensionHelper;
import org.potomacframework.build.extensionproc.AntFunction;
import org.potomacframework.build.extensionproc.AntType;
import org.potomacframework.build.extensionproc.AntVariable;

import com.elementriver.potomac.shared.BundleModel;
import com.elementriver.potomac.shared.ExtensionsMetadataProcessor;
import com.elementriver.potomac.shared.PDefinition;
import com.elementriver.potomac.shared.PFunction;
import com.elementriver.potomac.shared.PType;
import com.elementriver.potomac.shared.PVariable;

import flex2.compiler.CompilationUnit;
import flex2.compiler.CompilerSwcContext;
import flex2.compiler.FileSpec;
import flex2.compiler.ResourceBundlePath;
import flex2.compiler.ResourceContainer;
import flex2.compiler.SourceList;
import flex2.compiler.SourcePath;
import flex2.compiler.SymbolTable;
import flex2.compiler.abc.AbcClass;
import flex2.compiler.abc.MetaData;
import flex2.compiler.abc.Method;
import flex2.compiler.abc.Variable;
import flex2.compiler.as3.reflect.As3Class;
import flex2.compiler.as3.reflect.TypeTable;
import flex2.compiler.extensions.IPreLinkExtension;
import flex2.compiler.util.QName;

public class CompilerExtension implements IPreLinkExtension
{
	public interface MetadataListener {
		public void metadataFound(MetaData metadata,PType containingType, PDefinition declaringDefinition);
	}

	private static final String EXTENSIONPOINT_META = "ExtensionPoint";
	private static final String EXTENSION_META = "Extension";
	
	private static int runCounter = 0;
	
	
	
	private boolean error = false;
	

    public void run( List sources, List compUnits, FileSpec arg2, SourceList arg3, SourcePath arg4, ResourceBundlePath arg5,
                     ResourceContainer arg6, SymbolTable symbolTable, CompilerSwcContext arg8,
                     flex2.compiler.common.Configuration arg9 )
    {

    	runCounter ++;
    	if (runCounter == 2)
    	{
    		//This runs twice for each build so only do our logic once
    		runCounter = 0;
    		return;
    	}
    	
    	try
    	{
	    	
	    	final AntExtensionHelper helper = new AntExtensionHelper(symbolTable, new File(BundleTask.currentBundleDirectory));
	    	final ArrayList<HashMap<String,String>> extensions = new ArrayList<HashMap<String,String>>();
	    	final ArrayList<HashMap<String,String>> extensionPoints = new ArrayList<HashMap<String,String>>();
	    	
	    	if (BundleTask.isVerbose())
	    		System.out.println("Parsing Extension Points");
	    	
	    	iterateMetadata(compUnits, new MetadataListener() {
				public void metadataFound(MetaData metadata,PType containingType, PDefinition declaringDefinition) {
					
					if (metadata.getID().equals(EXTENSIONPOINT_META) && declaringDefinition instanceof PType)
					{
						HashMap<String,String> extPt = getMapFromTag(metadata);
						ArrayList<String> msgs = ExtensionsMetadataProcessor.validateExtensionPoint(extPt, helper);
						for (Iterator iterator = msgs.iterator(); iterator
								.hasNext();) {
							String msg = (String) iterator.next();
							System.out.println("Potomac error in " +containingType.getName()+" while parsing the metadata tag '"+metadata.getID()+"' on element '"+declaringDefinition.getName()+"':  "+ msg);
							error = true;
						}
						
						if (msgs.size() == 0)
						{
							extPt.put("bundle",BundleTask.currentBundle);
							extPt.put("declaredBy",declaringDefinition.getName());
							extensionPoints.add(extPt);
						}
					}
				}
			});
	    	
	    	final BundleModel model = BundleTask.bundleModelManager.getModel(BundleTask.currentBundle);
	    	model.extensionPoints = extensionPoints;
	    	
	    	if (BundleTask.isVerbose())
	    		System.out.println("Found " + extensionPoints.size() + " Extension Points.");
	    	
	    	final ArrayList<HashMap<String,String>> allExtPts = new ArrayList<HashMap<String,String>>();
	    	
	    	allExtPts.addAll(extensionPoints);
	    	
	    	//we're adding all ext pts from all depends, this is not the greatest strategy at the moment
	    	//if a bundle is in the workspace path and has not yet been built, then its bundle model is going
	    	//to be missing its exts and ext pts (since we're reading the root bundle.xml and not the /bin/bundle.xml
	    	for (String depend : model.dependencies)
	    	{
	    		allExtPts.addAll(BundleTask.bundleModelManager.getModel(depend).extensionPoints);
	    	}
	    	
	    	
	    	if (BundleTask.isVerbose())
	    		System.out.println("Parsing Extensions");
	    	
	    	iterateMetadata(compUnits, new MetadataListener() {
				public void metadataFound(MetaData metadata,PType containingType, PDefinition declaringDefinition) {
					
					HashMap<String,String> ext = getMapFromTag(metadata);
	
					String point = metadata.getID();
					if (metadata.getID().equals(EXTENSION_META))
					{
						point = ext.get("point");
					}
					else
					{
						ext.put("point",point);
					}
					
					HashMap<String,String> extPt = null;
					if (point != null)
						extPt = findExtPoint(point, allExtPts);
					
	
					if (extPt != null)
					{
	
						ArrayList<String> msgs = ExtensionsMetadataProcessor.validateExtension(ext,extPt,containingType,declaringDefinition, helper,model);
						for (Iterator iterator = msgs.iterator(); iterator
								.hasNext();) {
							String msg = (String) iterator.next();
							System.out.println("Potomac error in " +containingType.getName()+" while parsing the metadata tag '"+metadata.getID()+"' on element '"+declaringDefinition.getName()+"':  "+ msg);
							error = true;
						}
						
	
						if (msgs.size() == 0)
						{
							if (declaringDefinition instanceof PFunction)
							{
								ext.put("function",declaringDefinition.getName());
								ext.put("functionSignature",getFunctionString((PFunction) declaringDefinition));
							}
							else if (declaringDefinition instanceof PVariable)
							{							
								ext.put("variable",declaringDefinition.getName());
								ext.put("variableType", ((PVariable)declaringDefinition).getType());
							}
							ext.put("bundle",BundleTask.currentBundle);
							ext.put("class",containingType.getName());
							extensions.add(ext);
						}	
					}
	
				}
			});
	    	
	    	model.extensions = extensions;
	    	
	    	if (BundleTask.isVerbose())
	    		System.out.println("Found " + extensions.size() + " extensions.");
    	}
    	catch (Exception e)
    	{
    		e.printStackTrace();
    		throw new RuntimeException(e);
    	}
	    	
    	if (error)
    	{
    		throw new RuntimeException("Potomac metadata validation failed.");
    	}
    }
    
	private String getFunctionString(PFunction func)
	{
		String funcString = "(";
		List<PVariable> vars = func.getArguments();
		for (PVariable var : vars)
		{
			String argType = var.getType();
			
			funcString += var.getName() + ":" + argType;
			if (var.hasDefault())
			{
				//funcString += "=" + ((IArgument)var).getDefaultValue();
				//The default value may contain quotes or other characters that
				//will interfere with the xml.  So for now we're just using 'default' to
				//record the fact that the it had a default value
				funcString += "=*";
			}
			funcString += ",";
		}
		if (funcString.endsWith(","))
		{
			funcString = funcString.substring(0,funcString.length() -1);
		}
		funcString += "):";
		String returnType = func.getReturnType();
		if (returnType == null)
		{
			funcString += "void";
		}
		else
		{
			funcString += returnType;
		}
		return funcString;
	}
    
    private HashMap<String,String> findExtPoint(String id,ArrayList<HashMap<String,String>> allExtPts)
    {
    	for(HashMap<String,String> extPt : allExtPts)
    	{
    		if (extPt.get("id").equals(id))
    			return extPt;
    	}
    	return null;
    }
    
    private HashMap<String,String> getMapFromTag(MetaData metadata)
    {
    	HashMap<String,String> map = new HashMap<String,String>();
    	
    	for (int i = 0; i < metadata.count(); i++) {
			map.put(metadata.getKey(i), metadata.getValue(i));
		}
    	
    	return map;
    }
    
    private void iterateMetadata(List compUnits, MetadataListener handler)
    {
    	for (Iterator iterator = compUnits.iterator(); iterator.hasNext();) {
			CompilationUnit object = (CompilationUnit) iterator.next();
			
			if (!object.getSource().isSwcScriptOwner())
			{
				for (Iterator iterator2 = object.classTable.entrySet().iterator(); iterator2
						.hasNext();) {
					
					AbcClass clz = (AbcClass) ((Entry) iterator2.next()).getValue();
					if (clz instanceof As3Class)
					{
						AntType containingType = new AntType(clz);
						
						As3Class clz3 = (As3Class)clz;
						try {
							Field f = clz3.getClass().getDeclaredField("metadata");
							f.setAccessible(true);
							List<MetaData> metadata = (List<MetaData>) f.get(clz3);
							if (metadata != null)
							{
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();
									
									handler.metadataFound(metaData2, containingType ,new AntType(clz3));
								}
							}
						} catch (Exception e) {
							throw new RuntimeException(e);
						}
						
						try {
							Field f = clz3.getClass().getDeclaredField("typeTable");
							f.setAccessible(true);
							TypeTable t = (TypeTable) f.get(clz3);
							
							
						} catch (Exception e) {
							throw new RuntimeException(e);
						}
						
						
						
						if (clz3.getVariableNames() != null)
						{
							for (QName var : clz3.getVariableNames()) {
								Variable var2 = clz3.getVariable(new String[]{var.getNamespace()}, var.localPart, false);
								if (var2 == null)
									continue;
								List<MetaData> metadata = var2.getMetaData();
								if (metadata == null)
									continue;
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();

									handler.metadataFound(metaData2, containingType, new AntVariable(var2));
								}
							}
						}
						
						if (clz3.getMethodNames() != null)
						{
							for (QName fn : clz3.getMethodNames())
							{						
								
								Method meth = clz3.getMethod(new String[]{fn.getNamespace()}, fn.localPart, false);
								if (meth == null)
									continue;
								
								List<MetaData> metadata = meth.getMetaData();
								if (metadata == null)
									continue;
								
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();

									handler.metadataFound(metaData2, containingType, new AntFunction(meth));
								}
								
							}
						}
						
						if (clz3.constructor != null)
						{
							List<MetaData> metadata = clz3.constructor.getMetaData();
							if (metadata != null)
							{							
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();
	
									handler.metadataFound(metaData2, containingType, new AntFunction(clz3.constructor));
								}
							}
						}
						
						if (clz3.getGetterNames() != null)
						{
							for (QName fn : clz3.getGetterNames())
							{						
							
								Method meth = clz3.getGetter(new String[]{fn.getNamespace()}, fn.localPart, false);
								if (meth == null)
									continue;
								
								List<MetaData> metadata = meth.getMetaData();
								if (metadata == null)
									continue;
								
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();

									handler.metadataFound(metaData2, containingType, new AntFunction(meth));
								}
								
							}
						}
				
						if (clz3.getSetterNames() != null)
						{
							for (QName fn : clz3.getSetterNames())
							{						
							
								Method meth = clz3.getSetter(new String[]{fn.getNamespace()}, fn.localPart, false);
								if (meth == null)
									continue;
								
								List<MetaData> metadata = meth.getMetaData();
								if (metadata == null)
									continue;
								
								for (Iterator iterator3 = metadata.iterator(); iterator3
										.hasNext();) {
									MetaData metaData2 = (MetaData) iterator3
											.next();

									handler.metadataFound(metaData2, containingType, new AntFunction(meth));
								}
								
							}
						}
					}
				}

			}
		}
    }


}
