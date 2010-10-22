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
package potomac.ui
{

	[ExtensionPoint(id="Action", type="potomac.ui.Action", declaredOn="classes", label="*string", icon="asset:png,gif,jpg")]
	[ExtensionPointDetails(id="Action", description="Declares a global Potomac action")]
	[ExtensionPointDetails(id="Action", attribute="label", description="Action's text label", order="1")]
	[ExtensionPointDetails(id="Action", attribute="icon", description="Action's image decorator", order="2")]

	/**
	 * An Action represents a runnable piece of logic that is typically represented on the
	 * UI.
	 */
	public class Action
	{
		public function Action()
		{
		}

		public function run():void
		{

		}

	}
}