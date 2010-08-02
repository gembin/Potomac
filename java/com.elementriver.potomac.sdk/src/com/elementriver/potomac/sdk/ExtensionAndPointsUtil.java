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

public class ExtensionAndPointsUtil {

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
		return contains(new String[]{"id","type","declaredOn","declaredBy","access","functionSignature","variableType","argumentsAsAttributes","idRequired","preloadRequired"},attribute);
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
