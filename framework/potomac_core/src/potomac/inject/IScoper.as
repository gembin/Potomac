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
	 * An IScoper allows callers to set the injection binding as a singleton.  Singleton
	 * injection bindings prevent more than one instance of the injection class from being created.
	 */
	public interface IScoper
	{

		/**
		 * Sets the injection binding as a singleton. 
		 */
		function asSingleton():void;

	}
}