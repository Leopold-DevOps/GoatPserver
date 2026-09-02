package com.company.assembleegameclient.screens
{
import com.company.assembleegameclient.screens.charrects.CharacterRectList;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import kabam.rotmg.core.model.PlayerModel;

/**
 * Scrolling viewport over the character rows.
 *
 * The mask is always present and its height is set by the owning screen from
 * the space actually available above the menu banner - it used to be created
 * only when the content happened to exceed 400px, and sized to a fixed
 * stageHeight-180, so a short list was left unmasked and drew straight over
 * the banner.
 */
public class CharacterList extends Sprite
{

    public static const WIDTH:int = 600;

    public static const HEIGHT:int = 430;


    public var charRectList_:CharacterRectList;

    private var maskShape:Shape;
    private var viewportHeight_:Number = 0;

    public function CharacterList(model:PlayerModel)
    {
        super();
        this.charRectList_ = new CharacterRectList();
        addChild(this.charRectList_);

        this.maskShape = new Shape();
        addChild(this.maskShape);
        mask = this.maskShape;
    }

    /** Height of the visible window onto the rows. */
    public function setViewportHeight(value:Number) : void
    {
        this.viewportHeight_ = Math.max(1, value);
        var g:Graphics = this.maskShape.graphics;
        g.clear();
        g.beginFill(0);
        g.drawRect(0, 0, WIDTH, this.viewportHeight_);
        g.endFill();
    }

    public function get viewportHeight() : Number
    {
        return this.viewportHeight_;
    }

    /**
     * Live height of the rows themselves. Read through the row container
     * rather than this sprite, whose height is clamped by the mask - and the
     * rows are populated after construction, so this cannot be cached.
     */
    public function get contentHeight() : Number
    {
        return this.charRectList_ == null ? 0 : this.charRectList_.height;
    }

    public function setPos(pos:Number) : void
    {
        this.charRectList_.y = pos;
    }
}
}
