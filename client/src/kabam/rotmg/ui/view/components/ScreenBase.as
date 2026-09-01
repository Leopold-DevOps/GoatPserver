package kabam.rotmg.ui.view.components
{
   import com.company.assembleegameclient.ui.SoundIcon;
   import flash.display.Shape;
   import flash.display.Sprite;
import flash.events.Event;

import kabam.rotmg.ui.view.TitleView_BackgroundLayer;
import kabam.rotmg.ui.view.TitleView_TitleScreenBackground;

import mx.core.BitmapAsset;

/**
 * Shared backdrop for the non-gameplay screens.
 *
 * Two backdrops are available. The default 800x600 TitleScreenBackground maps
 * 1:1 onto the stage. Passing menuBackground uses the title screen's 880x680
 * art instead, which is authored with 40px of overscan, so it has to be
 * cover-scaled and centred rather than stretched to the stage - otherwise it
 * would both distort and sit off-centre.
 */
public class ScreenBase extends Sprite
   {
      private static var graphic:BitmapAsset;
      /* Static to match `graphic`, which is itself static: only one of these
         screens is ever on stage at a time, and reSize() has to know which
         backdrop the live one is using. */
      private static var menuBg:Boolean = false;
      private static var darken:Shape;
      /** Matches TitleView's scrim so both menus read the same. */
      private static const DARKEN:Number = 0.35;

      public function ScreenBase(menuBackground:Boolean = false)
      {
         super();
         menuBg = menuBackground;
         graphic = menuBackground
            ? new TitleView_BackgroundLayer()
            : new TitleView_TitleScreenBackground();
         addChild(graphic);
         darken = new Shape();
         addChild(darken);
         layoutGraphic();
         //addChild(this.darkenFactory.create());
         addChild(new SoundIcon());
      }

      public static function reSize(e:Event):void
      {
         layoutGraphic();
      }

      private static function layoutGraphic():void
      {
         if (graphic == null)
         {
            return;
         }
         var sw:Number = WebMain.STAGE.stageWidth;
         var sh:Number = WebMain.STAGE.stageHeight;
         if (darken != null)
         {
            darken.graphics.clear();
            if (menuBg)
            {
               darken.graphics.beginFill(0, DARKEN);
               darken.graphics.drawRect(0, 0, sw, sh);
               darken.graphics.endFill();
            }
         }
         if (menuBg)
         {
            var cover:Number = Math.max(sw / 800, sh / 600);
            graphic.scaleX = cover;
            graphic.scaleY = cover;
            graphic.x = (sw - 880 * cover) / 2;
            graphic.y = (sh - 680 * cover) / 2;
         }
         else
         {
            graphic.scaleX = sw / 800;
            graphic.scaleY = sh / 600;
            graphic.x = 0;
            graphic.y = 0;
         }
      }
   }
}
