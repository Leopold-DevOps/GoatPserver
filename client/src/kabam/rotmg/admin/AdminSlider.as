package kabam.rotmg.admin {
import com.company.ui.SimpleText;

import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextFieldAutoSize;

/**
 * A compact labelled integer slider. Reports its value while dragging via
 * onChange, and once more on release via onCommit so callers can avoid
 * spamming the server on every pixel of movement.
 */
public class AdminSlider extends Sprite {

    private static const TRACK_WIDTH:int = 108;
    private static const TRACK_HEIGHT:int = 4;
    private static const KNOB_RADIUS:int = 5;

    public var onChange:Function;
    public var onCommit:Function;

    private var label:String;
    private var minValue:int;
    private var maxValue:int;
    private var value:int;

    private var track:Shape;
    private var fill:Shape;
    private var knob:Shape;
    private var text:SimpleText;
    private var dragging:Boolean = false;

    public function AdminSlider(label:String, minValue:int, maxValue:int, value:int) {
        this.label = label;
        this.minValue = minValue;
        this.maxValue = Math.max(maxValue, minValue);
        this.value = clamp(value);

        this.text = new SimpleText(11, 0xCCCCCC, false, 200, 0);
        this.text.autoSize = TextFieldAutoSize.LEFT;
        addChild(this.text);

        this.track = new Shape();
        this.track.y = 15;
        addChild(this.track);

        this.fill = new Shape();
        this.fill.y = 15;
        addChild(this.fill);

        this.knob = new Shape();
        this.knob.y = 15 + TRACK_HEIGHT / 2;
        addChild(this.knob);

        drawTrack();
        redraw();

        addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
    }

    private function drawTrack():void {
        this.track.graphics.clear();
        this.track.graphics.beginFill(0x1A1A1A, 1);
        this.track.graphics.drawRoundRect(0, 0, TRACK_WIDTH, TRACK_HEIGHT, 4, 4);
        this.track.graphics.endFill();

        // invisible hit area so the whole row is grabbable, not just the knob
        graphics.clear();
        graphics.beginFill(0, 0);
        graphics.drawRect(-4, 0, TRACK_WIDTH + 8, 26);
        graphics.endFill();
    }

    private function redraw():void {
        var ratio:Number = this.maxValue == this.minValue
                ? 0
                : (this.value - this.minValue) / (this.maxValue - this.minValue);
        var knobX:Number = ratio * TRACK_WIDTH;

        this.fill.graphics.clear();
        this.fill.graphics.beginFill(0x4E9E4E, 1);
        this.fill.graphics.drawRoundRect(0, 0, Math.max(knobX, 1), TRACK_HEIGHT, 4, 4);
        this.fill.graphics.endFill();

        this.knob.graphics.clear();
        this.knob.graphics.beginFill(this.dragging ? 0xFFFFFF : 0xDDDDDD, 1);
        this.knob.graphics.drawCircle(0, 0, KNOB_RADIUS);
        this.knob.graphics.endFill();
        this.knob.x = knobX;

        this.text.setText(this.label + ": " + this.value + " / " + this.maxValue);
    }

    private function clamp(v:int):int {
        if (v < this.minValue) return this.minValue;
        if (v > this.maxValue) return this.maxValue;
        return v;
    }

    private function valueFromMouse():int {
        var ratio:Number = mouseX / TRACK_WIDTH;
        if (ratio < 0) ratio = 0;
        if (ratio > 1) ratio = 1;
        return clamp(Math.round(this.minValue + ratio * (this.maxValue - this.minValue)));
    }

    private function onMouseDown(e:MouseEvent):void {
        this.dragging = true;
        setValueFromMouse();
        if (stage != null) {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
        }
    }

    private function onMouseMove(e:MouseEvent):void {
        setValueFromMouse();
        e.updateAfterEvent();
    }

    private function onMouseUp(e:MouseEvent):void {
        this.dragging = false;
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
        }
        redraw();
        if (this.onCommit != null)
            this.onCommit(this.value);
    }

    private function setValueFromMouse():void {
        var next:int = valueFromMouse();
        if (next == this.value) {
            redraw();
            return;
        }
        this.value = next;
        redraw();
        if (this.onChange != null)
            this.onChange(this.value);
    }

    /** Refresh from the outside (server pushed a new stat value). */
    public function setBounds(minValue:int, maxValue:int):void {
        this.minValue = minValue;
        this.maxValue = Math.max(maxValue, minValue);
        this.value = clamp(this.value);
        redraw();
    }

    public function setValue(v:int):void {
        if (this.dragging)
            return; // don't fight the user's hand
        this.value = clamp(v);
        redraw();
    }

    public function getValue():int {
        return this.value;
    }
}
}
