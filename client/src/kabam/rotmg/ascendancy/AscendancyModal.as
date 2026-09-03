package kabam.rotmg.ascendancy {

import com.company.assembleegameclient.game.GameSprite;
import com.company.ui.SimpleText;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

/**
 * The ascendancy tree window.
 *
 * Drawn entirely in vector for now. The pieces that will eventually become art
 * - the frame, the tab strip, the node sockets, the connectors - are each built
 * in their own method so they can be replaced one at a time without unpicking
 * the layout or the interaction.
 *
 * Nothing here writes to the character. See AscendancyState.
 */
public class AscendancyModal extends Sprite {

    public static const WIDTH:int = 566;
    public static const HEIGHT:int = 548;

    private static const PAD:int = 18;
    private static const HEADER_H:int = 44;
    private static const TAB_H:int = 30;
    private static const GRID_TOP:int = 132;
    private static const ROW_H:int = 84;
    private static const INFO_H:int = 92;

    /** Which tab the window is showing - nodes read this when they redraw. */
    public static var currentTab:int = AscendancyData.ROAD;

    private var gs:GameSprite;
    private var frame:Shape;
    private var links:Shape;
    private var tabStrip:Sprite;
    private var grid:Sprite;
    private var title:SimpleText;
    private var points:SimpleText;
    private var blurb:SimpleText;
    private var infoName:SimpleText;
    private var infoText:SimpleText;
    private var resetBtn:Sprite;

    public function AscendancyModal(gs:GameSprite) {
        super();
        this.gs = gs;
        currentTab = AscendancyState.chosenPath == -1
            ? AscendancyData.ROAD : AscendancyState.chosenPath;

        this.frame = new Shape();
        addChild(this.frame);
        buildHeader();
        this.tabStrip = new Sprite();
        addChild(this.tabStrip);
        this.links = new Shape();
        addChild(this.links);
        this.grid = new Sprite();
        addChild(this.grid);
        buildInfoPanel();
        buildResetButton();

        drawFrame();
        rebuild();

        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }

    private function onAdded(e:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        filters = [new DropShadowFilter(0, 0, 0, 0.75, 22, 22)];
    }

    // ---------- chrome ----------

    private function drawFrame():void {
        var g:* = this.frame.graphics;
        g.clear();
        g.beginFill(0x16161A, 0.97);
        g.lineStyle(2, 0xD4A030, 1);
        g.drawRoundRect(0, 0, WIDTH, HEIGHT, 6, 6);
        g.endFill();
        // header underline, and the band the info panel sits in
        g.lineStyle(1, 0x33353F, 1);
        g.moveTo(PAD, HEADER_H);
        g.lineTo(WIDTH - PAD, HEADER_H);
        g.beginFill(0x101014, 0.9);
        g.lineStyle(1, 0x2A2C34, 1);
        g.drawRoundRect(PAD, HEIGHT - INFO_H - PAD, WIDTH - PAD * 2, INFO_H, 4, 4);
        g.endFill();
    }

    private function buildHeader():void {
        this.title = new SimpleText(20, 0xD4A030, false, 0, 0);
        this.title.setBold(true);
        this.title.text = "Ascendancy";
        this.title.updateMetrics();
        this.title.x = PAD;
        this.title.y = 11;
        addChild(this.title);

        this.points = new SimpleText(13, 0xA8B0C0, false, 0, 0);
        this.points.x = PAD;
        this.points.y = HEADER_H + 8;
        addChild(this.points);

        this.blurb = new SimpleText(12, 0x767E8F, false, WIDTH - PAD * 2, 0);
        this.blurb.wordWrap = true;
        this.blurb.x = PAD;
        this.blurb.y = HEADER_H + 26;
        addChild(this.blurb);

        // SimpleText is a TextField, so it cannot carry buttonMode itself -
        // wrap it in a Sprite to get a real hit area and the hand cursor.
        var closeLabel:SimpleText = new SimpleText(18, 0x9A9FAC, false, 0, 0);
        closeLabel.setBold(true);
        closeLabel.text = "X";
        closeLabel.updateMetrics();
        closeLabel.mouseEnabled = false;
        var close:Sprite = new Sprite();
        close.graphics.beginFill(0xFFFFFF, 0);
        close.graphics.drawRect(0, 0, closeLabel.width + 10, 26);
        close.graphics.endFill();
        closeLabel.x = 5;
        close.addChild(closeLabel);
        close.x = WIDTH - PAD - (closeLabel.width + 10);
        close.y = 9;
        close.buttonMode = true;
        close.useHandCursor = true;
        close.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            AscendancyModalController.close();
        });
        addChild(close);
    }

    private function buildInfoPanel():void {
        var top:int = HEIGHT - INFO_H - PAD;
        this.infoName = new SimpleText(14, 0xE8EAF0, false, 0, 0);
        this.infoName.setBold(true);
        this.infoName.x = PAD + 12;
        this.infoName.y = top + 10;
        addChild(this.infoName);

        this.infoText = new SimpleText(12, 0xA8B0C0, false, WIDTH - PAD * 2 - 24, 0);
        this.infoText.wordWrap = true;
        this.infoText.x = PAD + 12;
        this.infoText.y = top + 30;
        addChild(this.infoText);
        showInfo(null);
    }

    private function buildResetButton():void {
        this.resetBtn = new Sprite();
        var label:SimpleText = new SimpleText(11, 0x9A9FAC, false, 0, 0);
        label.text = "Reset tab";
        label.updateMetrics();
        var g:* = this.resetBtn.graphics;
        g.beginFill(0x101014, 1);
        g.lineStyle(1, 0x3A3D47, 1);
        g.drawRoundRect(0, 0, label.width + 18, 20, 3, 3);
        g.endFill();
        label.x = 9;
        label.y = 3;
        this.resetBtn.addChild(label);
        this.resetBtn.x = WIDTH - PAD - (label.width + 18);
        this.resetBtn.y = HEADER_H + 6;
        this.resetBtn.buttonMode = true;
        this.resetBtn.addEventListener(MouseEvent.CLICK, function (e:MouseEvent):void {
            AscendancyState.resetTab(currentTab);
            rebuild();
        });
        addChild(this.resetBtn);
    }

    // ---------- tabs ----------

    private function buildTabs():void {
        while (this.tabStrip.numChildren > 0)
            this.tabStrip.removeChildAt(0);

        var x:int = PAD;
        for (var i:int = 0; i < AscendancyData.TAB_NAMES.length; i++) {
            var open:Boolean = AscendancyState.isTabOpen(i);
            var active:Boolean = i == currentTab;
            var accent:uint = uint(AscendancyData.TAB_COLORS[i]);

            var label:SimpleText = new SimpleText(12, active ? 0xFFFFFF : (open ? 0x9A9FAC : 0x4A4D57), false, 0, 0);
            if (active)
                label.setBold(true);
            label.text = String(AscendancyData.TAB_NAMES[i]);
            label.updateMetrics();

            var tab:Sprite = new Sprite();
            var w:int = label.width + 22;
            var g:* = tab.graphics;
            g.beginFill(active ? accent : 0x101014, active ? 0.22 : 0.9);
            g.lineStyle(1, active ? accent : 0x2A2C34, 1);
            g.drawRoundRect(0, 0, w, TAB_H, 3, 3);
            g.endFill();
            label.x = 11;
            label.y = (TAB_H - 16) / 2;
            tab.addChild(label);
            tab.x = x;
            tab.y = HEIGHT - INFO_H - PAD - TAB_H - 10;

            if (open) {
                tab.buttonMode = true;
                tab.addEventListener(MouseEvent.CLICK, makeTabHandler(i));
            }
            this.tabStrip.addChild(tab);
            x += w + 6;
        }
    }

    private function makeTabHandler(index:int):Function {
        return function (e:MouseEvent):void {
            currentTab = index;
            rebuild();
        };
    }

    // ---------- the grid ----------

    private function rebuild():void {
        buildTabs();
        this.points.text = AscendancyState.pointsLeft(currentTab) + " of "
            + AscendancyData.pointsFor(currentTab) + " points unspent";
        this.points.updateMetrics();
        this.blurb.text = String(AscendancyData.TAB_BLURB[currentTab]);
        this.blurb.updateMetrics();

        while (this.grid.numChildren > 0)
            this.grid.removeChildAt(0);

        var accent:uint = uint(AscendancyData.TAB_COLORS[currentTab]);
        var nodes:Array = AscendancyData.nodes(currentTab);
        var colX:Array = [WIDTH * 0.26, WIDTH * 0.5, WIDTH * 0.74];

        drawLinks(nodes, colX, accent);

        for each (var def:Object in nodes) {
            var view:AscendancyNode = new AscendancyNode(def, accent);
            var tier:int = int(def.tier);
            // the keystone row holds two, centred, rather than the three above
            if (tier == 3) {
                view.x = int(def.col) == 0 ? WIDTH * 0.36 : WIDTH * 0.64;
                view.y = GRID_TOP + ROW_H * 3 - 6;
            } else {
                view.x = Number(colX[int(def.col)]);
                view.y = GRID_TOP + ROW_H * tier;
            }
            view.addEventListener(MouseEvent.CLICK, makeNodeHandler(view));
            view.addEventListener(MouseEvent.ROLL_OVER, makeInfoHandler(view));
            this.grid.addChild(view);

            var caption:SimpleText = new SimpleText(10, 0x8A91A0, false, 108, 0);
            caption.wordWrap = true;
            caption.text = String(def.name);
            caption.useTextDimensions();
            caption.x = view.x - 54;
            caption.y = view.y + (view.isKeystone ? 30 : 26);
            caption.mouseEnabled = false;
            this.grid.addChild(caption);
        }
    }

    /** Connectors are drawn from the same column positions the nodes use, so
        the two can never disagree about where a line should land. */
    private function drawLinks(nodes:Array, colX:Array, accent:uint):void {
        var g:* = this.links.graphics;
        g.clear();
        for (var tier:int = 0; tier < 3; tier++) {
            var reached:Boolean = AscendancyState.isTierReachable(currentTab, tier + 1);
            g.lineStyle(2, reached ? accent : 0x2A2C34, reached ? 0.55 : 1);
            var y0:Number = GRID_TOP + ROW_H * tier + AscendancyNode.RADIUS;
            var y1:Number = GRID_TOP + ROW_H * (tier + 1) - AscendancyNode.RADIUS;
            if (tier == 2) {
                y1 = GRID_TOP + ROW_H * 3 - 6 - AscendancyNode.KEY_RADIUS;
                g.moveTo(WIDTH * 0.5, y0);
                g.lineTo(WIDTH * 0.5, (y0 + y1) / 2);
                g.moveTo(WIDTH * 0.36, (y0 + y1) / 2);
                g.lineTo(WIDTH * 0.64, (y0 + y1) / 2);
                g.moveTo(WIDTH * 0.36, (y0 + y1) / 2);
                g.lineTo(WIDTH * 0.36, y1);
                g.moveTo(WIDTH * 0.64, (y0 + y1) / 2);
                g.lineTo(WIDTH * 0.64, y1);
                if (AscendancyData.nodes(currentTab).length < 11)
                    g.clear();
                continue;
            }
            for (var c:int = 0; c < 3; c++) {
                g.moveTo(Number(colX[c]), y0);
                g.lineTo(Number(colX[c]), y1);
            }
        }
    }

    private function makeNodeHandler(view:AscendancyNode):Function {
        return function (e:MouseEvent):void {
            if (AscendancyState.allocate(currentTab, view.node))
                rebuild();
            showInfo(view.node);
        };
    }

    private function makeInfoHandler(view:AscendancyNode):Function {
        return function (e:MouseEvent):void {
            showInfo(view.node);
        };
    }

    private function showInfo(def:Object):void {
        if (def == null) {
            this.infoName.text = "Choose a node";
            this.infoText.text = AscendancyState.chosenPath == -1
                ? "Putting a point into any ascendancy commits you to it - the other two close."
                : "Hover a node to read what it does. Effects are not applied yet.";
        } else {
            var taken:int = AscendancyState.ranksIn(def.id);
            this.infoName.text = String(def.name)
                + (int(def.ranks) > 1 ? "  (" + taken + "/" + def.ranks + ")" : "")
                + (def.keystone ? "  - keystone, costs " + AscendancyData.KEYSTONE_COST : "");
            this.infoText.text = String(def.effect);
        }
        this.infoName.updateMetrics();
        this.infoText.useTextDimensions();
    }

    public function close():void {
        if (parent != null)
            parent.removeChild(this);
    }
}
}
