package kabam.rotmg.ascendancy {

import com.company.assembleegameclient.game.GameSprite;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

import kabam.rotmg.assets.EmbeddedAssets;

/**
 * The ascendancy tree window, laid out inside the painted panel.
 *
 * The art already carries the frame, the title plate, the close button and the
 * dark regions the UI sits in, so nothing here draws chrome any more - it only
 * fills the regions. Those regions are held as FRACTIONS of the artwork rather
 * than pixel constants, so re-exporting the panel at a different resolution
 * needs no code change; only the fractions would move if the art itself were
 * re-composed.
 *
 * Nothing here writes to the character. See AscendancyState.
 */
public class AscendancyModal extends Sprite {

    /** Sized to the play area; the art's own aspect fixes the height. */
    public static const WIDTH:int = 590;
    public static const HEIGHT:int = 393;

    // Regions measured off the artwork, as fractions of its width/height.
    private static const LEFT_RAIL:Array   = [0.0234, 0.0889, 0.1400, 0.7559];
    private static const RIGHT_RAIL:Array  = [0.8483, 0.0889, 0.9753, 0.7559];
    private static const CENTRE:Array      = [0.1480, 0.0889, 0.8420, 0.7559];
    private static const INFO_BAR:Array    = [0.0234, 0.7783, 0.9753, 0.9570];
    private static const CLOSE_BOX:Array   = [0.9557, 0.0195, 0.9870, 0.0625];
    private static const RING:Array        = [0.1120, 0.8720, 0.0470];

    /** Which tab the window is showing - nodes read this when they redraw. */
    public static var currentTab:int = AscendancyData.ROAD;

    private var gs:GameSprite;
    private var links:Shape;
    private var rail:Sprite;
    private var grid:Sprite;
    private var ringGlyph:Shape;
    private var pathName:SimpleText;
    private var pointsBig:SimpleText;
    private var pointsSub:SimpleText;
    private var infoName:SimpleText;
    private var infoText:SimpleText;
    private var resetBtn:Sprite;

    public function AscendancyModal(gs:GameSprite) {
        super();
        this.gs = gs;
        currentTab = AscendancyState.chosenPath == -1
            ? AscendancyData.ROAD : AscendancyState.chosenPath;

        var art:Bitmap = new Bitmap(new EmbeddedAssets.ascendancyPanel().bitmapData);
        art.smoothing = true;
        addChild(art);

        this.links = new Shape();
        addChild(this.links);
        this.grid = new Sprite();
        addChild(this.grid);
        this.rail = new Sprite();
        addChild(this.rail);

        buildRightRail();
        buildInfoBar();
        buildCloseHit();

        rebuild();
        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }

    private function onAdded(e:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        filters = [new DropShadowFilter(0, 0, 0, 0.8, 24, 24)];
    }

    // ---------- region helpers ----------

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

    // ---------- right rail: points and reset ----------

    private function buildRightRail():void {
        var x0:Number = rx(RIGHT_RAIL[0]) + 6;
        var w:Number = rx(RIGHT_RAIL[2]) - rx(RIGHT_RAIL[0]) - 12;

        this.pathName = new SimpleText(10, 0xD4A030, false, w, 0);
        this.pathName.wordWrap = true;
        this.pathName.x = x0;
        this.pathName.y = ry(RIGHT_RAIL[1]) + 10;
        addChild(this.pathName);

        this.pointsBig = new SimpleText(26, 0xFFFFFF, false, w, 0);
        this.pointsBig.setBold(true);
        this.pointsBig.x = x0;
        this.pointsBig.y = ry(RIGHT_RAIL[1]) + 48;
        addChild(this.pointsBig);

        this.pointsSub = new SimpleText(9, 0x8A91A0, false, w, 0);
        this.pointsSub.wordWrap = true;
        this.pointsSub.x = x0;
        this.pointsSub.y = ry(RIGHT_RAIL[1]) + 80;
        addChild(this.pointsSub);

        this.resetBtn = new Sprite();
        var label:SimpleText = new SimpleText(9, 0x9A9FAC, false, 0, 0);
        label.text = "Reset";
        label.updateMetrics();
        label.mouseEnabled = false;
        var g:* = this.resetBtn.graphics;
        g.beginFill(0x0C0C10, 1);
        g.lineStyle(1, 0x4A4030, 1);
        g.drawRoundRect(0, 0, w, 18, 3, 3);
        g.endFill();
        label.x = (w - label.width) / 2;
        label.y = 2;
        this.resetBtn.addChild(label);
        this.resetBtn.x = x0;
        this.resetBtn.y = ry(RIGHT_RAIL[3]) - 26;
        this.resetBtn.buttonMode = true;
        this.resetBtn.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            AscendancyState.resetTab(currentTab);
            rebuild();
        });
        addChild(this.resetBtn);
    }

    // ---------- info bar: the ring plus the hovered node ----------

    private function buildInfoBar():void {
        this.ringGlyph = new Shape();
        this.ringGlyph.x = rx(RING[0]);
        this.ringGlyph.y = ry(RING[1]);
        addChild(this.ringGlyph);

        var textX:Number = rx(RING[0]) + rx(RING[2]) + 18;
        var textW:Number = rx(INFO_BAR[2]) - textX - 12;

        this.infoName = new SimpleText(13, 0xE8D9B0, false, textW, 0);
        this.infoName.setBold(true);
        this.infoName.x = textX;
        this.infoName.y = ry(INFO_BAR[1]) + 12;
        addChild(this.infoName);

        this.infoText = new SimpleText(11, 0xA8B0C0, false, textW, 0);
        this.infoText.wordWrap = true;
        this.infoText.x = textX;
        this.infoText.y = ry(INFO_BAR[1]) + 32;
        addChild(this.infoText);
        showInfo(null);
    }

    /** Stands in for the eventual node portrait inside the painted ring. */
    private function drawRingGlyph(def:Object, accent:uint):void {
        var g:* = this.ringGlyph.graphics;
        g.clear();
        if (def == null)
            return;
        var r:Number = rx(RING[2]) * 0.52;
        g.beginFill(accent, AscendancyState.ranksIn(def.id) > 0 ? 0.9 : 0.4);
        if (def.keystone) {
            g.moveTo(0, -r); g.lineTo(r, 0); g.lineTo(0, r); g.lineTo(-r, 0); g.lineTo(0, -r);
        } else {
            g.drawRect(-r * 0.18, -r, r * 0.36, r * 2);
            g.drawRect(-r, -r * 0.18, r * 2, r * 0.36);
        }
        g.endFill();
    }

    // ---------- left rail: the tabs ----------

    private function buildRail():void {
        while (this.rail.numChildren > 0)
            this.rail.removeChildAt(0);

        var x0:Number = rx(LEFT_RAIL[0]) + 5;
        var w:Number = rx(LEFT_RAIL[2]) - rx(LEFT_RAIL[0]) - 10;
        var y:Number = ry(LEFT_RAIL[1]) + 10;

        for (var i:int = 0; i < AscendancyData.TAB_SHORT.length; i++) {
            var open:Boolean = AscendancyState.isTabOpen(i);
            var active:Boolean = i == currentTab;
            var accent:uint = uint(AscendancyData.TAB_COLORS[i]);

            var label:SimpleText = new SimpleText(10,
                active ? 0xFFFFFF : (open ? 0x9A9FAC : 0x4A4D57), false, w - 10, 0);
            label.wordWrap = true;
            if (active)
                label.setBold(true);
            label.text = String(AscendancyData.TAB_SHORT[i]);
            label.useTextDimensions();
            label.mouseEnabled = false;

            var h:Number = Math.max(26, label.height + 10);
            var tab:Sprite = new Sprite();
            var g:* = tab.graphics;
            g.beginFill(active ? accent : 0x0C0C10, active ? 0.28 : 0.85);
            g.lineStyle(1, active ? accent : 0x33353F, 1);
            g.drawRoundRect(0, 0, w, h, 3, 3);
            g.endFill();
            label.x = 5;
            label.y = (h - label.height) / 2;
            tab.addChild(label);
            tab.x = x0;
            tab.y = y;

            if (open) {
                tab.buttonMode = true;
                tab.addEventListener(MouseEvent.CLICK, makeTabHandler(i));
            }
            this.rail.addChild(tab);
            y += h + 6;
        }
    }

    private function makeTabHandler(index:int):Function {
        return function (e:MouseEvent):void {
            currentTab = index;
            rebuild();
        };
    }

    // ---------- the node grid, over the painted tree ----------

    private function rebuild():void {
        buildRail();

        var left:int = AscendancyState.pointsLeft(currentTab);
        this.pathName.text = String(AscendancyData.TAB_NAMES[currentTab]).toUpperCase();
        this.pathName.useTextDimensions();
        this.pointsBig.text = String(left);
        this.pointsBig.updateMetrics();
        this.pointsSub.text = "of " + AscendancyData.pointsFor(currentTab) + " points unspent";
        this.pointsSub.useTextDimensions();

        while (this.grid.numChildren > 0)
            this.grid.removeChildAt(0);

        var accent:uint = uint(AscendancyData.TAB_COLORS[currentTab]);
        var nodes:Array = AscendancyData.nodes(currentTab);
        drawLinks(nodes, accent);

        for each (var def:Object in nodes) {
            var view:AscendancyNode = new AscendancyNode(def, accent);
            view.x = nodeX(int(def.tier), int(def.col));
            view.y = nodeY(int(def.tier));
            view.addEventListener(MouseEvent.CLICK, makeNodeHandler(view, accent));
            view.addEventListener(MouseEvent.ROLL_OVER, makeInfoHandler(view, accent));
            this.grid.addChild(view);
        }
    }

    /** Columns for tiers 0-2, and the narrower pair the keystone row uses. */
    private function nodeX(tier:int, col:int):Number {
        var x0:Number = rx(CENTRE[0]), w:Number = rx(CENTRE[2]) - x0;
        if (tier == 3)
            return x0 + w * (col == 0 ? 0.37 : 0.63);
        return x0 + w * [0.26, 0.50, 0.74][col];
    }

    private function nodeY(tier:int):Number {
        var y0:Number = ry(CENTRE[1]), h:Number = ry(CENTRE[3]) - y0;
        return y0 + h * (0.13 + 0.25 * tier);
    }

    /** Drawn from the same helpers the nodes use, so lines and sockets can
        never disagree about where a connection lands. */
    private function drawLinks(nodes:Array, accent:uint):void {
        var g:* = this.links.graphics;
        g.clear();
        var hasKeystones:Boolean = nodes.length > 9;

        for (var tier:int = 0; tier < 3; tier++) {
            if (tier == 2 && !hasKeystones)
                break;
            var reached:Boolean = AscendancyState.isTierReachable(currentTab, tier + 1);
            g.lineStyle(2, reached ? accent : 0x2A2C34, reached ? 0.5 : 0.7);

            var yA:Number = nodeY(tier) + AscendancyNode.RADIUS;
            var yB:Number = nodeY(tier + 1) - (tier == 2 ? AscendancyNode.KEY_RADIUS : AscendancyNode.RADIUS);

            if (tier == 2) {
                var mid:Number = (yA + yB) / 2;
                g.moveTo(nodeX(0, 1), yA);
                g.lineTo(nodeX(0, 1), mid);
                g.moveTo(nodeX(3, 0), mid);
                g.lineTo(nodeX(3, 1), mid);
                g.moveTo(nodeX(3, 0), mid);
                g.lineTo(nodeX(3, 0), yB);
                g.moveTo(nodeX(3, 1), mid);
                g.lineTo(nodeX(3, 1), yB);
            } else {
                for (var c:int = 0; c < 3; c++) {
                    g.moveTo(nodeX(tier, c), yA);
                    g.lineTo(nodeX(tier, c), yB);
                }
            }
        }
    }

    private function makeNodeHandler(view:AscendancyNode, accent:uint):Function {
        return function (e:MouseEvent):void {
            if (AscendancyState.allocate(currentTab, view.node))
                rebuild();
            showInfo(view.node);
        };
    }

    private function makeInfoHandler(view:AscendancyNode, accent:uint):Function {
        return function (e:MouseEvent):void {
            showInfo(view.node);
        };
    }

    private function showInfo(def:Object):void {
        var accent:uint = uint(AscendancyData.TAB_COLORS[currentTab]);
        if (def == null) {
            this.infoName.text = String(AscendancyData.TAB_NAMES[currentTab]);
            this.infoText.text = AscendancyState.chosenPath == -1
                ? String(AscendancyData.TAB_BLURB[currentTab])
                  + "  Spending a point in any ascendancy commits you - the other two close."
                : String(AscendancyData.TAB_BLURB[currentTab]);
        } else {
            var taken:int = AscendancyState.ranksIn(def.id);
            this.infoName.text = String(def.name)
                + (int(def.ranks) > 1 ? "   " + taken + " / " + def.ranks : "")
                + (def.keystone ? "   keystone, costs " + AscendancyData.KEYSTONE_COST : "");
            this.infoText.text = String(def.effect);
        }
        this.infoName.useTextDimensions();
        this.infoText.useTextDimensions();
        drawRingGlyph(def, accent);
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
