package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.parameters.Parameters;

import flash.display.Bitmap;
import flash.display.Sprite;

import kabam.rotmg.assets.custom.images.HudPane;
import kabam.rotmg.constants.UiMetrics;

public class CharacterWindowBackground extends Sprite
   {


      public function CharacterWindowBackground()
      {
         /* The pane art is authored at exactly UiMetrics.HUD_WIDTH x 600 with the
            surround already keyed to alpha, so the vines and lantern overhang the
            play area instead of sitting on a hard rectangle. */
         var pane:Bitmap = new Bitmap(new HudPane().bitmapData);
         addChild(pane);

         /* The window is taller than the art on tall displays; carry the frame's
            own colour down past the bottom edge rather than showing a seam. */
         var skirt:Sprite = new Sprite();
         skirt.graphics.beginFill(0x1B1109);
         skirt.graphics.drawRect(0, pane.height, UiMetrics.HUD_WIDTH, 2500 - pane.height);
         skirt.graphics.endFill();
         addChildAt(skirt, 0);
      }
   }
}
