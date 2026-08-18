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

    /** Width of the HUD pane pinned to the right edge - matches the art. */
    public static const HUD_WIDTH:int = 286;

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
    public static const ITEM_TILE_WIDTH:int = 51;
    public static const ITEM_TILE_HEIGHT:int = 41;

    public static const ITEM_GRID_PADDING_X:int = 6;
    public static const ITEM_GRID_PADDING_Y:int = 8;

    /** Cells per row. Inventory is 8 slots, equipment 4. */
    public static const ITEM_GRID_COLUMNS:int = 4;

    /** Left edge of every item grid, measured from the pane's left edge. */
    public static const ITEM_GRID_X:int = 30;

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

    /** Equipment row - four slots. */
    public static const HUD_EQUIPMENT_Y:int = 343;

    /**
     * Tab strip. Its content sits TAB_TOP_OFFSET (27) below this, and the
     * mediator insets content by a further 7, so the first inventory row lands
     * at 394 + 27 + 7 = 428 - exactly on the painted recess.
     */
    public static const HUD_TAB_STRIP_Y:int = 394;
    public static const HUD_TAB_STRIP_HEIGHT:int = 130;

    /** Potion counters along the bottom. */
    public static const HUD_POTIONS_Y:int = 529;

    public static const HUD_INTERACT_Y:int = 500;

    /** Usable width for content inside the pane. */
    public static function get HUD_CONTENT_WIDTH():int {
        return HUD_WIDTH - HUD_CONTENT_INSET * 2;
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
