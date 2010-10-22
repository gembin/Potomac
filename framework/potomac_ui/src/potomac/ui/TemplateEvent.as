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
	import flash.events.Event;

	/**
	 * TemplateEvents are the communication mechanism between templates and Potomac.
	 * In response to a these events, a template is expected to modify the UI as appropriate.
	 */
	public class TemplateEvent extends Event
	{
		/**
		 * The TemplateEvent.INITIALIZE constant defines the value of the
		 * <code>type</code> property of the event object
		 * for a <code>templateInitialize</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
		 *       event listener that handles the event. For example, if you use
		 *       <code>myButton.addEventListener()</code> to register an event listener,
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>parameters</code></td><td>A dynamic object containing the parameters specified in the appManifest.xml</td></tr>
		 *     <tr><td><code>pageDescriptor</code></td><td>null</td></tr>
		 *     <tr><td><code>pageInput</code></td><td>null</td></tr>
		 *     <tr><td><code>pageOptions</code></td><td>null</td></tr>
		 *     <tr><td><code>page</code></td><td>null</td></tr>
		 *     <tr><td><code>setFocus</code></td><td>null</td></tr>
		 *  </table>
		 *
		 * @eventType templateInitialize
		 */
		public static const INITIALIZE:String="templateInitialize";
		/**
		 * The TemplateEvent.OPEN_PAGE constant defines the value of the
		 * <code>type</code> property of the event object
		 * for a <code>templateOpenPage</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
		 *       event listener that handles the event. For example, if you use
		 *       <code>myButton.addEventListener()</code> to register an event listener,
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>parameters</code></td><td>null</td></tr>
		 *     <tr><td><code>pageDescriptor</code></td><td>The page descriptor.</td></tr>
		 *     <tr><td><code>pageInput</code></td><td>the page's input</td></tr>
		 *     <tr><td><code>pageOptions</code></td><td>the page options</td></tr>
		 *     <tr><td><code>page</code></td><td>the page</td></tr>
		 *     <tr><td><code>setFocus</code></td><td>true if the page should be made visible</td></tr>
		 *  </table>
		 *
		 * @eventType templateOpenPage
		 */
		public static const OPEN_PAGE:String="templateOpenPage";
		/**
		 * The TemplateEvent.SHOW_PAGE constant defines the value of the
		 * <code>type</code> property of the event object
		 * for a <code>templateShowPage</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
		 *       event listener that handles the event. For example, if you use
		 *       <code>myButton.addEventListener()</code> to register an event listener,
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>parameters</code></td><td>null</td></tr>
		 *     <tr><td><code>pageDescriptor</code></td><td>null</td></tr>
		 *     <tr><td><code>pageInput</code></td><td>null</td></tr>
		 *     <tr><td><code>pageOptions</code></td><td>null</td></tr>
		 *     <tr><td><code>page</code></td><td>The page to show.</td></tr>
		 *     <tr><td><code>setFocus</code></td><td>null</td></tr>
		 *  </table>
		 *
		 * @eventType templateShowPage
		 */
		public static const SHOW_PAGE:String="templateShowPage";
		/**
		 * The TemplateEvent.CLOSE_PAGE constant defines the value of the
		 * <code>type</code> property of the event object
		 * for a <code>templateClosePage</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
		 *       event listener that handles the event. For example, if you use
		 *       <code>myButton.addEventListener()</code> to register an event listener,
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>parameters</code></td><td>null</td></tr>
		 *     <tr><td><code>pageDescriptor</code></td><td>null</td></tr>
		 *     <tr><td><code>pageInput</code></td><td>null</td></tr>
		 *     <tr><td><code>pageOptions</code></td><td>null</td></tr>
		 *     <tr><td><code>page</code></td><td>The page to close.</td></tr>
		 *     <tr><td><code>setFocus</code></td><td>null</td></tr>
		 *  </table>
		 *
		 * @eventType templateClosePage
		 */
		public static const CLOSE_PAGE:String="templateClosePage";

		/**
		 * The TemplateEvent.PAGE_DIRTY_CHANGE constant defines the value of the
		 * <code>type</code> property of the event object
		 * for a <code>templatePageDirtyChange</code> event.
		 *
		 *  <p>The properties of the event object have the following values:</p>
		 *  <table class="innertable">
		 *     <tr><th>Property</th><th>Value</th></tr>
		 *     <tr><td><code>bubbles</code></td><td>false</td></tr>
		 *     <tr><td><code>cancelable</code></td><td>false</td></tr>
		 *     <tr><td><code>currentTarget</code></td><td>The Object that defines the
		 *       event listener that handles the event. For example, if you use
		 *       <code>myButton.addEventListener()</code> to register an event listener,
		 *       myButton is the value of the <code>currentTarget</code>. </td></tr>
		 *     <tr><td><code>parameters</code></td><td>null</td></tr>
		 *     <tr><td><code>pageDescriptor</code></td><td>null</td></tr>
		 *     <tr><td><code>pageInput</code></td><td>null</td></tr>
		 *     <tr><td><code>pageOptions</code></td><td>null</td></tr>
		 *     <tr><td><code>page</code></td><td>The page whose dirty state changed.</td></tr>
		 *     <tr><td><code>setFocus</code></td><td>null</td></tr>
		 *  </table>
		 *
		 * @eventType templatePageDirtyChange
		 */
		public static const PAGE_DIRTY_CHANGE:String="templatePageDirtyChange";


		private var _parameters:Object;

		private var _pageDescriptor:PageDescriptor;
		private var _pageInput:PageInput;
		private var _pageOptions:PageOptions;
		private var _setFocus:Boolean;

		private var _page:Page;

		/**
		 * Callers should not construct TemplateEvent instances.
		 */
		public function TemplateEvent(type:String, parameters:Object, pageDesc:PageDescriptor, pageInput:PageInput, pageOptions:PageOptions, page:Page, setFocus:Boolean)
		{
			super(type);
			_parameters=parameters;
			_pageDescriptor=pageDesc;
			_pageInput=pageInput;
			_pageOptions=pageOptions;
			_page=page;
			_setFocus=setFocus;
		}

		/**
		 * The parameters associated with this template, as specified in the application's appManifest.xml.
		 */
		public function get parameters():Object
		{
			return _parameters;
		}

		/**
		 * The page's descriptor.
		 */
		public function get descriptor():PageDescriptor
		{
			return _pageDescriptor;
		}

		/**
		 * The page's input.
		 */
		public function get input():PageInput
		{
			return _pageInput;
		}

		/**
		 * The page options.
		 */
		public function get options():PageOptions
		{
			return _pageOptions;
		}

		/**
		 * True if the page should be made visible and focused.
		 */
		public function get setFocus():Boolean
		{
			return _setFocus;
		}

		/**
		 * The page to show or close.
		 */
		public function get page():Page
		{
			return _page;
		}

		override public function clone():Event
		{
			return new TemplateEvent(type, _parameters, _pageDescriptor, _pageInput, _pageOptions, _page, _setFocus);
		}

	}
}