package potomac.ui.templates.dark
{
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	
	public class BackgroundPattern extends UIComponent
	{
		public function BackgroundPattern()
		{
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(width,80,Math.PI / 2);
			graphics.beginGradientFill(GradientType.LINEAR,[0x605C55,0x000000],[1,1],[0,255],matrix);
			graphics.drawRect(0,0,width,80);
			graphics.endFill();
			
			var y:int = height - 200;
			if (y < 200)
				y=200;
			
			var matrix2:Matrix = new Matrix();
			matrix2.createGradientBox(width,200,Math.PI / 2,0,y);
			graphics.beginGradientFill(GradientType.LINEAR,[0x000000,0x818181],[1,1],[0,255],matrix2);
			graphics.drawRect(0,y,width,200);
			graphics.endFill();		
		}

	}
}