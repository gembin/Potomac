/*******************************************************************************
 *  Copyright (c) 2010 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package potomac.core
{
	import flash.events.EventDispatcher;
	
	import potomac.bundle.IBundleService;
	import potomac.inject.Injector;

	/**
	 * LaunchRunner provides the logic that executes an application after the 
	 * initial Potomac bootstrapping is complete.  See TemplateRunner for the
	 * default behavior.
	 * <p>
	 * Extenders should override the #run method and provide their custom application
	 * startup behavior.  A StartupEvent.LAUNCHRUNNER_COMPLETE event must be dispatched
	 * when the runner's initial startup behavior is complete.  This event tells the 
	 * Launcher to finalize its startup logic (typically this means bringing down any 
	 * custom preloaders).
	 * </p>
	 */
	public class LaunchRunner extends EventDispatcher
	{
		/**
		 * Runs the application startup logic.
		 * 
		 * @param bundleService the bundle service.
		 * @param injector the injector.
		 */
		public function run(bundleService:IBundleService,injector:Injector):void
		{			
		}
	}
}