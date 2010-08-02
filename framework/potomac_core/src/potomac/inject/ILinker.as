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
	 * An ILinker links a injectable class or interface to an 
	 * implementation or implementation provider.
	 */
	public interface ILinker extends IScoper
	{
		/**
		 * Links an injectable to the given class.  Instances of the 
		 * given class will be created to satisfy injection requests.
		 * 
		 * @param clazz class to link to injectable
		 * @return an IScoper to allow for scope refinement
		 */		
		function toClass(clazz:Class):IScoper;
		
		/**
		 * Links the injectable to the given instance.
		 * 
		 * @param instance instance to link to the injectable 
		 */		
		function toInstance(instance:Object):void;
		
		/**
		 * Links an injectable to the given provider.
		 * 
		 * @param providerClass provider class to request injection instance from
		 * @return an IScoper to allow for scope refinement 
		 */		
		function toProvider(providerClass:Class):IScoper;
		
		/**
		 * Links an injectable to the given provider.
		 * 
		 * @param providerInstance provider to request injection instance from
		 * @return an IScoper to allow for scope refinement 
		 */		
		function toProviderInstance(providerInstance:IProvider):IScoper;
		
	}
}