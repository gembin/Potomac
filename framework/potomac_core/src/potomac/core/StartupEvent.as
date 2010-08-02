package potomac.core
{
	import flash.events.Event;
	
	/**
	 * StartupEvents are associated with Potomac's startup process.  These events are 
	 * associated with [StartupListener]s or IPotomacPreloaders.
	 */
	public class StartupEvent extends Event
	{
		/**
		 * The StartupEvent.POTOMAC_INITIALIZED constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>potomacInitialized</code> event.
		 * 
		 * This event is dispatched to [StartupListener]s to allow them a hook after 
		 * the initial bundles have been loaded but before the application's template has
		 * been created.  Startup listeners are typically used to show a login dialog 
		 * and/or to allow for loading additional bundles dynamically.		 * 
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
		 *  </table>
		 *
		 * @eventType potomacInitialized
		 */
		public static const POTOMAC_INITIALIZED:String = "potomacInitialized";
		
		/**
		 * The StartupEvent.STARTUPLISTENER_COMPLETE constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>potomacStartupListenerComplete</code> event.
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
		 *  </table>
		 *
		 * @eventType potomacStartupListenerComplete
		 */
		public static const STARTUPLISTENER_COMPLETE:String = "potomacStartupListenerComplete";
		
		/**
		 * The StartupEvent.PRELOADER_CLOSE_START constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>preloaderCloseStart</code> event.
		 * 
		 * This event is dispatched on IPotomacPrealoder's to notify them that they may 
		 * begin closing themselves.  Typically this means running some sort of animation.
		 * The preloader is expected to dispatch PRELOADER_CLOSE_COMPLETE when the 
		 * animation is complete and the preloader may be closed.
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
		 *  </table>
		 *
		 * @eventType preloaderCloseStart
		 */
		public static const PRELOADER_CLOSE_START:String = "preloaderCloseStart";
		
		/**
		 * The StartupEvent.PRELOADER_CLOSE_COMPLETE constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>preloaderCloseComplete</code> event.
		 * 
		 * This event is dispatched by an IPotomacPreloader (after it has received a 
		 * PRELOADER_CLOSE_START) to notify the Potomac core code that it is ready 
		 * to be closed.  This event is typically dispatched after an animation has
		 * been executed on the preloader.
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
		 *  </table>
		 *
		 * @eventType preloaderCloseComplete
		 */
		public static const PRELOADER_CLOSE_COMPLETE:String = "preloaderCloseComplete";
		
		/**
		 * The StartupEvent.LAUNCHRUNNER_COMPLETE constant defines the value of the 
		 * <code>type</code> property of the event object 
		 * for a <code>launchRunnerComplete</code> event.
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
		 *  </table>
		 *
		 * @eventType launchRunnerComplete
		 */
		public static const LAUNCHRUNNER_COMPLETE:String = "launchRunnerComplete";
		
		/**
		 * Constructs a StartupEvent of the given type.
		 */
		public function StartupEvent(type:String)
		{
			super(type);
		}
	}
}