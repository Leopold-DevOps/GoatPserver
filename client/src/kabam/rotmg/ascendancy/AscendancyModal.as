package kabam.rotmg.ascendancy {

import com.company.assembleegameclient.game.GameSprite;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextFormat;

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

    /** Width the medallion is drawn at; the art is twice this. */
    private static const MEDAL_W:int = 62;
    /** Centre of the medallion's orb, as a fraction of the medallion art. */
    private static const MEDAL_ORB:Array = [0.4995, 0.2999];

    /** One ascendancy point per two character levels: 2, 4, 6 and so on. */
    public static const LEVELS_PER_POINT:int = 2;

    public static function pointsForLevel(level:int):int {
        return int(level / LEVELS_PER_POINT);
    }

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
        buildPointsRail();
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

    /** Centred text sized to the rail, since the rail is narrow enough that
        everything in it has to wrap. */
    private function railText(size:int, color:uint, bold:Boolean, width:Number):SimpleText {
        var t:SimpleText = new SimpleText(size, color, false, width, 0);
        t.wordWrap = true;
        if (bold)
            t.setBold(true);
        var fmt:TextFormat = t.defaultTextFormat;
        fmt.align = "center";
        t.defaultTextFormat = fmt;
        t.mouseEnabled = false;
        return t;
    }

    /**
     * Left rail: how many points are unspent, and where they come from.
     *
     * Points are read from the character's level when the window opens - there
     * is nothing to spend them on yet, so earned and available are the same
     * number for now.
     */
    private function buildPointsRail():void {
        var x0:Number = rx(LEFT_RAIL[0]);
        var w:Number = rx(LEFT_RAIL[2]) - x0;
        var inner:Number = w - 8;
        var y:Number = ry(LEFT_RAIL[1]) + 8;

        var title:SimpleText = railText(11, 0xE8D9B0, true, inner);
        title.text = "Points Available";
        title.useTextDimensions();
        title.x = x0 + 4;
        title.y = y;
        addChild(title);
        y += title.height + 6;

        var medal:Bitmap = new Bitmap(new EmbeddedAssets.pointsMedal().bitmapData);
        medal.smoothing = true;
        var medalH:Number = MEDAL_W * medal.bitmapData.height / medal.bitmapData.width;
        medal.width = MEDAL_W;
        medal.height = medalH;
        medal.x = x0 + (w - MEDAL_W) / 2;
        medal.y = y;
        addChild(medal);

        var level:int = (this.gs != null && this.gs.map != null && this.gs.map.player_ != null)
            ? this.gs.map.player_.level_ : 0;
        var value:SimpleText = railText(19, 0xFFFFFF, true, MEDAL_W);
        value.text = String(pointsForLevel(level));
        value.useTextDimensions();
        value.width = MEDAL_W;
        value.x = medal.x;
        value.y = medal.y + medalH * MEDAL_ORB[1] - value.height / 2;
        value.filters = [new DropShadowFilter(0, 0, 0, 0.9, 4, 4)];
        addChild(value);
        y += medalH + 10;

        var note:SimpleText = railText(9, 0x9A9FAC, false, inner);
        note.text = "Earn a point every " + LEVELS_PER_POINT
            + " levels on this character.";
        note.useTextDimensions();
        note.x = x0 + 4;
        note.y = y;
        addChild(note);
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
