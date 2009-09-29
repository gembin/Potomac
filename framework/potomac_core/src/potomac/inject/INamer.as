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
package potomac.inject
{
	/**
	 * An INamer allows injectable bindings to be associated with a textual name.
	 *  
	 */	
	public interface INamer extends ILinker
	{
		/**
		 * Links an injectable to the given name.
		 *  
		 * @param name name to link injectable to
		 * @return an ILinker to allow further injectable linking details 
		 */
		function named(name:String):ILinker;		
	}
}