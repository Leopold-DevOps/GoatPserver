package kabam.rotmg.ascendancy {

import com.company.ui.SimpleText;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

/**
 * One clickable node.
 *
 * Everything is drawn with vector shapes on purpose: the socket, the ring and
 * the fill are separate layers, so replacing the placeholder look with real art
 * later means swapping the `icon` layer and re-skinning `redraw`, without
 * touching layout, hit testing or state.
 */
public class AscendancyNode extends Sprite {

    public static const RADIUS:int = 21;
    public static const KEY_RADIUS:int = 26;

    public var node:Object;
    private var accent:uint;
    private var body:Shape;
    /** Placeholder stands in for the eventual icon bitmap. */
    private var icon:Shape;
    private var pip:SimpleText;
    private var hovered:Boolean = false;

    public function AscendancyNode(node:Object, accent:uint) {
        super();
        this.node = node;
        this.accent = accent;

        this.body = new Shape();
        addChild(this.body);
        this.icon = new Shape();
        addChild(this.icon);

        this.pip = new SimpleText(11, 0xFFFFFF, false, 0, 0);
        this.pip.setBold(true);
        this.pip.filters = [new DropShadowFilter(0, 0, 0, 1, 3, 3)];
        addChild(this.pip);

        buttonMode = true;
        useHandCursor = true;
        addEventListener(MouseEvent.ROLL_OVER, onOver);
        addEventListener(MouseEvent.ROLL_OUT, onOut);
        redraw();
    }

    public function get isKeystone():Boolean {
        return node.keystone == true;
    }

    private function get radius():int {
        return isKeystone ? KEY_RADIUS : RADIUS;
    }

    private function onOver(e:MouseEvent):void {
        this.hovered = true;
        redraw();
    }

    private function onOut(e:MouseEvent):void {
        this.hovered = false;
        redraw();
    }

    /**
     * Three states carry three different jobs, so each gets its own visual
     * channel rather than all of them fighting over brightness:
     * reachability is the ring, allocation is the fill, hover is the halo.
     */
    public function redraw():void {
        var tab:int = AscendancyModal.currentTab;
        var taken:int = AscendancyState.ranksIn(node.id);
        var reachable:Boolean = AscendancyState.isTierReachable(tab, int(node.tier))
            && AscendancyState.isTabOpen(tab);
        var maxed:Boolean = taken >= int(node.ranks);

        var g:* = this.body.graphics;
        g.clear();

        if (this.hovered && reachable) {
            g.beginFill(accent, 0.18);
            g.drawCircle(0, 0, radius + 5);
            g.endFill();
        }

        // socket
        g.beginFill(taken > 0 ? accent : 0x101014, taken > 0 ? 0.30 : 0.85);
        g.lineStyle(taken > 0 ? 2.5 : 1.5, taken > 0 ? accent : (reachable ? 0x6A7180 : 0x33353F), 1);
        if (isKeystone)
            drawDiamond(g, radius);
        else
            g.drawCircle(0, 0, radius);
        g.endFill();

        // placeholder for the icon art - a simple glyph so the node is not empty
        var ig:* = this.icon.graphics;
        ig.clear();
        var glyph:uint = taken > 0 ? accent : (reachable ? 0x8A91A0 : 0x44474F);
        ig.beginFill(glyph, 1);
        if (isKeystone) {
            drawDiamond(ig, 9);
        } else {
            ig.drawRect(-2, -8, 4, 16);
            ig.drawRect(-8, -2, 16, 4);
        }
        ig.endFill();

        // rank pip, only where there is more than one rank to track
        if (int(node.ranks) > 1) {
            this.pip.text = taken + "/" + node.ranks;
            this.pip.updateMetrics();
            this.pip.x = -this.pip.width / 2;
            this.pip.y = radius - 2;
            this.pip.visible = true;
        } else {
            this.pip.visible = false;
        }

        alpha = reachable || taken > 0 ? 1 : 0.55;
        filters = maxed ? [new DropShadowFilter(0, 0, accent, 0.9, 10, 10, 1.4)] : [];
    }

    private function drawDiamond(g:*, r:Number):void {
        g.moveTo(0, -r);
        g.lineTo(r, 0);
        g.lineTo(0, r);
        g.lineTo(-r, 0);
        g.lineTo(0, -r);
    }
}
}
