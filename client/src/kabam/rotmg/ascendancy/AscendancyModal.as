package kabam.rotmg.ascendancy {

import com.company.assembleegameclient.game.GameSprite;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

import kabam.rotmg.assets.EmbeddedAssets;

/**
 * The ascendancy tree window.
 *
 * Currently the panel and nothing else - the tree is being rebuilt a slice at
 * a time, so this deliberately holds no nodes, tabs or text.
 *
 * Resolution: the art is authored well above the size it is drawn at and then
 * scaled DOWN to fit, rather than authored at the drawn size. Fullscreen
 * magnifies the UI, and a panel baked at its logical size has no pixels left
 * to give when that happens - it just gets resampled bigger and goes soft.
 * Holding the extra resolution means a magnified panel is still drawing from
 * real detail. The scale is derived from the bitmap's own size, so the art can
 * be re-exported at any resolution and this keeps working.
 */
public class AscendancyModal extends Sprite {

    /** Logical size. The art is larger than this; see the class note. */
    public static const WIDTH:int = 590;
    public static const HEIGHT:int = 393;

    /**
     * Regions measured off the artwork, as fractions of its width and height,
     * kept for when the tree is built back up. Nothing draws into them yet.
     * Fractions rather than pixels so they survive the art being re-exported.
     */
    public static const LEFT_RAIL:Array  = [0.0234, 0.0889, 0.1400, 0.7559];
    public static const RIGHT_RAIL:Array = [0.8483, 0.0889, 0.9753, 0.7559];
    public static const CENTRE:Array     = [0.1480, 0.0889, 0.8420, 0.7559];
    public static const INFO_BAR:Array   = [0.0234, 0.7783, 0.9753, 0.9570];
    public static const RING:Array       = [0.1120, 0.8720, 0.0470];
    private static const CLOSE_BOX:Array = [0.9557, 0.0195, 0.9870, 0.0625];

    private var gs:GameSprite;

    public function AscendancyModal(gs:GameSprite) {
        super();
        this.gs = gs;

        var art:Bitmap = new Bitmap(new EmbeddedAssets.ascendancyPanel().bitmapData);
        art.smoothing = true;
        art.scaleX = WIDTH / art.bitmapData.width;
        art.scaleY = HEIGHT / art.bitmapData.height;
        addChild(art);

        buildCloseHit();
        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }

    private function onAdded(e:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        filters = [new DropShadowFilter(0, 0, 0, 0.8, 24, 24)];
    }

    private static function rx(f:Number):Number { return f * WIDTH; }
    private static function ry(f:Number):Number { return f * HEIGHT; }

    /** The close button is painted into the art; this only adds its hit area. */
    private function buildCloseHit():void {
        var hit:Sprite = new Sprite();
        var x0:Number = rx(CLOSE_BOX[0]), y0:Number = ry(CLOSE_BOX[1]);
        var w:Number = rx(CLOSE_BOX[2]) - x0, h:Number = ry(CLOSE_BOX[3]) - y0;
        hit.graphics.beginFill(0xFFFFFF, 0);
        hit.graphics.drawRect(0, 0, w + 6, h + 6);
        hit.graphics.endFill();
        hit.x = x0 - 3;
        hit.y = y0 - 3;
        hit.buttonMode = true;
        hit.useHandCursor = true;
        hit.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            AscendancyModalController.close();
        });
        addChild(hit);
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
