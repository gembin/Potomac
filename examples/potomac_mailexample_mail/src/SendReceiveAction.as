package
{
	import flash.events.Event;
	
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
			var partRef:PartReference = page.getFolder("default").findPart("inboxlist");
			if (partRef.control != null) //truthfully we know this won't be null because the part is the first to be shown/created
			{
				partRef.control.dispatchEvent(new Event("sendreceive"));
			}
		}
		
	}
}