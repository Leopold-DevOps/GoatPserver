package com.company.assembleegameclient.screens
{
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.geom.ColorTransform;

/**
 * Painted plate behind a single class in the classes grid, replacing the old
 * FullCharBoxGraphic / LockedCharBoxGraphic swf sprites.
 *
 * CharacterBox positions its portrait, stars and label against graphic_.width,
 * so this reports a fixed size rather than whatever the bitmap happens to be.
 * The art is portrait (990x1388), so the box is taller than it is wide and the
 * grid's row pitch in NewCharacterScreen is set to suit.
 */
public class ClassBoxGraphic extends Sprite
{
    public static const BOX_W:int = 100;
    public static const BOX_H:int = 132;

    /* Interior of the painted frame, measured off the art: the top 23px is
       the gem ornament, so anything drawn from y0 sits on top of it. */
    public static const WELL_TOP:int = 23;
    public static const WELL_BOTTOM:int = 128;

    public function ClassBoxGraphic(locked:Boolean = false)
    {
        super();
        var art:Bitmap = new ClassBoxFrame();
        art.width = BOX_W;
        art.height = BOX_H;
        if (locked)
        {
            /* Dimmed rather than a separate asset - a locked class only needs
               to read as unavailable. */
            art.transform.colorTransform =
                new ColorTransform(0.45, 0.45, 0.45, 1, 0, 0, 0, 0);
        }
        addChild(art);
    }
}
}
