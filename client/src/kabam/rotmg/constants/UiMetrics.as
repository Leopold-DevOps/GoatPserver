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
    public static const HUD_DESIGN_WIDTH:int = 245;

    /**
     * Uniform shrink applied to the whole HUD pane. HUDView is scaled by this
     * (see GameSprite), so the art and every widget inside it come down
     * together and stay aligned with the painted recesses.
     */
    public static const HUD_SCALE:Number = 1.0;

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
     * Measured off HudPane.png (245x600): slot recesses are square, 33px, with
     * columns at x 34/80/125/170 (pitch 45) and rows at y 257 / 320 / 364
     * (pitch 44). Re-measure if the art is redrawn.
     */
    public static const ITEM_TILE_WIDTH:int = 33;
    public static const ITEM_TILE_HEIGHT:int = 33;

    public static const ITEM_GRID_PADDING_X:int = 12;
    public static const ITEM_GRID_PADDING_Y:int = 11;

    /** Cells per row. Inventory is 8 slots, equipment 4. */
    public static const ITEM_GRID_COLUMNS:int = 4;

    /** Left edge of every item grid - the painted recesses start at x 34. */
    public static const ITEM_GRID_X:int = 34;

    /**
     * Size argument handed to ObjectLibrary.getRedrawnTextureFromType.
     *
     * TextureRedrawer.resize renders 5 * (size/100) * sourceDimension, and
     * oversized art is normalised to an 8px equivalent first, so the on-screen
     * icon works out to size * 0.4 px: 70 -> 28px, which clears the 33px cell
     * with a little margin.
     */
    public static const ITEM_ICON_SIZE:int = 70;

    /** Total width a grid of the given column count occupies. */
    public static function gridWidth(columns:int):int {
        return columns * ITEM_TILE_WIDTH + (columns - 1) * ITEM_GRID_PADDING_X;
    }

    // ------------------------------------------------------- hud vertical

    /* Measured from the pane art. */
    public static const HUD_MINIMAP_X:int = 13;
    public static const HUD_MINIMAP_Y:int = 26;
    public static const HUD_MINIMAP_WIDTH:int = 212;
    public static const HUD_MINIMAP_HEIGHT:int = 132;

    /** Name + class icon. The art has no dedicated plate, so this sits at
        the top of the empty wood panel below the inventory. */
    public static const HUD_DETAILS_Y:int = 404;

    /**
     * Reserved: the pane art has a fourth groove above the XP bar, kept
     * empty for the adventurer rank / reputation meter. Nothing draws here
     * yet - HUD_BAR_Y covers only the three live meters below it.
     */
    public static const HUD_RANK_BAR_Y:int = 166;

    public static const HUD_BAR_Y:Array = [192, 214, 234];
    public static const HUD_BAR_HEIGHT:int = 13;

    /** Groove interior runs x 37 - 200 on the art. */
    public static const HUD_BAR_X:int = 37;
    public static const HUD_BAR_WIDTH:int = 164;
    public static const HUD_STAT_METERS_Y:int = 192;

    /** Equipment row - four slots. Painted recess runs y 257-290. */
    public static const HUD_EQUIPMENT_Y:int = 257;

    /**
     * Tab strip. Its content sits TAB_TOP_OFFSET (27) below this, and the
     * mediator insets content by a further 7, so the first inventory row lands
     * at 286 + 27 + 7 = 320 - exactly on the painted recess.
     */
    public static const HUD_TAB_STRIP_Y:int = 286;
    /* Tall enough that the potion row (y 444) still fits inside the tab
       content, and the non-inventory panel covers the empty wood area. */
    public static const HUD_TAB_STRIP_HEIGHT:int = 170;

    /** Potion counters along the bottom. */
    public static const HUD_POTIONS_Y:int = 444;

    /**
     * Interact panel (portal name, Locked/Full). Sits near the top of the
     * empty wood area, just under the second inventory row (which ends at
     * 396), rather than sinking to the bottom of the pane.
     */
    public static const HUD_INTERACT_Y:int = 410;

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
