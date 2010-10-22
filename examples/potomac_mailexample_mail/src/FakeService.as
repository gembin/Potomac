package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
         
	public class FakeService extends EventDispatcher
	{
		public static const SERVICE_COMPLETE:String = "fakeComplete";
		
		private var _timer:Timer;
		
		public function FakeService()
		{
			super();
		}
		
		public function go(millis:int):void
		{
			_timer = new Timer(millis,1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE,onTimerComplete);
			_timer.start();
		}
		
		private function onTimerComplete(e:TimerEvent):void
		{
			dispatchEvent(new Event(SERVICE_COMPLETE));
		}
		
	}
}