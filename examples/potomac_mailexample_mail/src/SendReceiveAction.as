package
{
	import flash.events.Event;
	
	import potomac.core.PotomacDispatcher;
	import potomac.ui.Action;
	import potomac.ui.Page;
	import potomac.ui.PartReference;
	import potomac.ui.PotomacUI;

	[Action(label="Send/Receive")] 
	public class SendReceiveAction extends Action
	{
		private var _potomacUI:PotomacUI;

		[Inject]  
		public function SendReceiveAction(potomacUI:PotomacUI)
		{
			super();
			_potomacUI = potomacUI;
		}
		
		override public function run():void
		{ 
			var page:Page = _potomacUI.findPage("mailpage");
			_potomacUI.showPage(page);
			
			PotomacDispatcher.getInstance().dispatch("sendreceive");
		}
		
	}
}