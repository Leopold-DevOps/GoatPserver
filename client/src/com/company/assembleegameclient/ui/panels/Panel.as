package com.company.assembleegameclient.ui.panels
{
   import com.company.assembleegameclient.game.GameSprite;
   import flash.display.Sprite;
   import kabam.rotmg.constants.UiMetrics;
   
   public class Panel extends Sprite
   {
      
      /* Derived from the pane geometry rather than hardcoded: every Panel
         subclass sizes its text and centres its buttons against WIDTH, so a
         stale literal here overflows the pane whenever the pane is redrawn. */
      public static const WIDTH:int = UiMetrics.HUD_INTERACT_WIDTH - UiMetrics.HUD_INTERACT_INSET * 2;
      
      public static const HEIGHT:int = 100 - 16;
       
      
      public var gs_:GameSprite;
      
      public function Panel(gs:GameSprite)
      {
         super();
         this.gs_ = gs;
      }
      
      public function draw() : void
      {
      }
   }
}
