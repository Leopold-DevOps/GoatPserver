package kabam.rotmg.constants {

/**
 * Geometry for the right-hand HUD pane and the item grids inside it.
 *
 * These were previously magic numbers scattered across ItemTile, ItemGrid,
 * ItemTileSprite, CharacterWindowBackground, GameSprite and Camera, which is
 * why item art was effectively locked to 8x8.
 *
 * The values below are measured off the pane artwork (HudPane.png, authored at
 * HUD_WIDTH x 600), not chosen by hand - so the live widgets land inside the
 * painted recesses. Re-measure if the art is redrawn.
 */
public class UiMetrics {

    /** The design-space stage. Everything else is expressed against this. */
    public static const STAGE_WIDTH:int = 800;
    public static const STAGE_HEIGHT:int = 600;

    /**
     * Design/layout space of the pane. HudPane.png is authored at exactly this
     * width, and every HUD_* constant below is measured against it, so this is
     * the coordinate space *inside* HUDView. Do not shrink this to make the HUD
     * smaller - use HUD_SCALE, which leaves the measured geometry intact.
     */
    public static const HUD_DESIGN_WIDTH:int = 286;

    /**
     * Uniform shrink applied to the whole HUD pane. HUDView is scaled by this
     * (see GameSprite), so the art and every widget inside it come down
     * together and stay aligned with the painted recesses.
     */
    public static const HUD_SCALE:Number = 0.82;

    /** On-screen footprint of the pane after HUD_SCALE. */
    public static function get HUD_WIDTH():int {
        return Math.round(HUD_DESIGN_WIDTH * HUD_SCALE);
    }

    /** Play area left of the HUD - drives the chat box and camera offset. */
    public static function get PLAY_WIDTH():int {
        return STAGE_WIDTH - HUD_WIDTH;
    }

    /** Inner content inset of the HUD pane. */
    public static const HUD_CONTENT_INSET:int = 7;

    // ---------------------------------------------------------------- items

    /*
     * The painted slot recesses are wider than they are tall, so tiles are not
     * square. Icon size is limited by the shorter axis.
     */
    /*
     * Re-measured directly off HudPane.png: the recesses run x 33/90/147/204,
     * 55 wide (pitch 57), and the rows are 46 tall with a 49 pitch. The old
     * 51x41 tiles centred 4.5px left and high of the painted recesses.
     */
    public static const ITEM_TILE_WIDTH:int = 55;
    public static const ITEM_TILE_HEIGHT:int = 46;

    public static const ITEM_GRID_PADDING_X:int = 2;
    public static const ITEM_GRID_PADDING_Y:int = 3;

    /** Cells per row. Inventory is 8 slots, equipment 4. */
    public static const ITEM_GRID_COLUMNS:int = 4;

    /** Left edge of every item grid - the painted recesses start at x 33. */
    public static const ITEM_GRID_X:int = 33;

    /**
     * Size argument handed to ObjectLibrary.getRedrawnTextureFromType.
     *
     * TextureRedrawer.resize renders 5 * (size/100) * sourceDimension, and
     * oversized art is normalised to an 8px equivalent first, so the on-screen
     * icon works out to size * 0.4 px: 90 -> 36px, which clears the 41px cell
     * height with a little margin.
     */
    public static const ITEM_ICON_SIZE:int = 90;

    /** Total width a grid of the given column count occupies. */
    public static function gridWidth(columns:int):int {
        return columns * ITEM_TILE_WIDTH + (columns - 1) * ITEM_GRID_PADDING_X;
    }

    // ------------------------------------------------------- hud vertical

    /* Measured from the pane art. */
    public static const HUD_MINIMAP_X:int = 23;
    public static const HUD_MINIMAP_Y:int = 17;
    public static const HUD_MINIMAP_WIDTH:int = 240;
    public static const HUD_MINIMAP_HEIGHT:int = 199;

    /** Name plate between the minimap and the bars. */
    public static const HUD_DETAILS_Y:int = 224;

    /** The three empty bar grooves (fame, hp, mp), each 17px tall. */
    public static const HUD_BAR_Y:Array = [260, 289, 317];
    public static const HUD_BAR_HEIGHT:int = 17;

    /** Groove interior runs x 34 - 249 on the art. */
    public static const HUD_BAR_X:int = 34;
    public static const HUD_BAR_WIDTH:int = 216;
    public static const HUD_STAT_METERS_Y:int = 260;

    /** Equipment row - four slots. Painted recess runs y 345-393. */
    public static const HUD_EQUIPMENT_Y:int = 345;

    /**
     * Tab strip. Its content sits TAB_TOP_OFFSET (27) below this, and the
     * mediator insets content by a further 7, so the first inventory row lands
     * at 397 + 27 + 7 = 431 - exactly on the painted recess.
     */
    public static const HUD_TAB_STRIP_Y:int = 397;
    /* Tall enough that the potion row (y 529) still fits inside the tab
       content, which now also has to host the solid non-inventory panel. */
    public static const HUD_TAB_STRIP_HEIGHT:int = 145;

    /** Potion counters along the bottom. */
    public static const HUD_POTIONS_Y:int = 529;

    /**
     * Interact panel (portal name, Locked/Full). Sits *below* the pane art,
     * which ends at 600 - at the old 500 it overlapped the inventory rows
     * (431-525) and the potion row, so the portal name drew on top of them.
     */
    public static const HUD_INTERACT_Y:int = 604;

    /** Usable width for content inside the pane. */
    public static function get HUD_CONTENT_WIDTH():int {
        /* design space - this is used inside the scaled HUDView */
        return HUD_DESIGN_WIDTH - HUD_CONTENT_INSET * 2;
    }

    /**
     * Vertical room the inventory tab has for item rows, after the tab buttons
     * (TabStripView.TAB_TOP_OFFSET) are taken off the top.
     */
    public static function get TAB_CONTENT_HEIGHT():int {
        return HUD_TAB_STRIP_HEIGHT - 27;
    }
}
}
