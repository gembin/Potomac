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
	 * An IProvider provides instances of an object for an injection binding.  Providers
	 * allow callers to add their own logic to the creation of classes during injection.
	 */
	public interface IProvider
	{
		/**
		 * Returns an instance of the necessary class for the injection binding.
		 * 
		 * @return An instance of the necessary class for the injection binding.
		 * 
		 */
		function getInstance():Object;
	}
}