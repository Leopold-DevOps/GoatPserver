package kabam.rotmg.game.view.components
{
   import flash.display.Bitmap;
   import flash.display.Sprite;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   
   public class TabView extends Sprite
   {
       
      
      public var index:int;
      
      private var bg:Sprite;
      
      private var icon:Bitmap;
      
      public function TabView(index:int, bg:Sprite, icon:Bitmap)
      {
         super();
         this.index = index;
         this.bg = bg;
         addChild(bg);
         if(icon)
         {
            this.icon = icon;
            /* Centre on the icon's visible pixels, not its bitmap: the source
               art fills a different amount of each 16x16 cell (9x11, 11x10,
               11x8...), so the old shared -5/-11 offset left them misaligned
               with one another. */
            var b:Rectangle = icon.bitmapData
               ? icon.bitmapData.getColorBoundsRect(0xFF000000, 0x00000000, false)
               : null;
            if(b != null && b.width > 0 && b.height > 0)
            {
               icon.x = TabStripView.TAB_WIDTH / 2 - (b.x + b.width / 2);
               icon.y = TabStripView.TAB_HEIGHT / 2 - (b.y + b.height / 2);
            }
            else
            {
               icon.x = icon.x - 5;
               icon.y = icon.y - 11;
            }
            addChild(icon);
         }
      }
      
      public function setSelected(selected:Boolean) : void
      {
         var ct:ColorTransform = this.bg.transform.colorTransform;
         ct.color = !!selected?uint(TabStripView.BACKGROUND_COLOR):uint(TabStripView.TAB_COLOR);
         this.bg.transform.colorTransform = ct;
      }
   }
}
