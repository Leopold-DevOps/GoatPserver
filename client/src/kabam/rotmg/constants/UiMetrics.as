package kabam.rotmg.constants {

/**
 * Geometry for the right-hand HUD pane and the item grids inside it.
 *
 * These were previously magic numbers scattered across ItemTile, ItemGrid,
 * ItemTileSprite, CharacterWindowBackground, GameSprite and Camera, which is
 * why item art was effectively locked to 8x8.
 *
 * The values below are measured off the pane artwork (HudPane.png, authored at
 * HUD_DESIGN_WIDTH x 600), not chosen by hand - so the live widgets land inside the
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
    public static const HUD_DESIGN_WIDTH:int = 204;

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
     * Measured off HudPane.png (204x600): slot recesses are square, 32px, with
     * columns at x 22/64/107/149 (pitch 42) and rows at y 248 / 311 / 356
     * (pitch 45). Re-measure if the art is redrawn.
     */
    public static const ITEM_TILE_WIDTH:int = 32;
    public static const ITEM_TILE_HEIGHT:int = 32;

    public static const ITEM_GRID_PADDING_X:int = 10;
    public static const ITEM_GRID_PADDING_Y:int = 13;

    /** Cells per row. Inventory is 8 slots, equipment 4. */
    public static const ITEM_GRID_COLUMNS:int = 4;

    /** Left edge of every item grid - the painted recesses start at x 34. */
    public static const ITEM_GRID_X:int = 22;

    /**
     * Size argument handed to ObjectLibrary.getRedrawnTextureFromType.
     *
     * TextureRedrawer.resize renders 5 * (size/100) * sourceDimension, and
     * oversized art is normalised to an 8px equivalent first, so the on-screen
     * icon works out to size * 0.4 px: 70 -> 28px, which clears the 32px cell
     * with a little margin.
     */
    public static const ITEM_ICON_SIZE:int = 70;

    /** Total width a grid of the given column count occupies. */
    public static function gridWidth(columns:int):int {
        return columns * ITEM_TILE_WIDTH + (columns - 1) * ITEM_GRID_PADDING_X;
    }

    // ------------------------------------------------------- hud vertical

    /* Measured from the pane art. */
    public static const HUD_MINIMAP_X:int = 22;
    public static const HUD_MINIMAP_Y:int = 24;
    public static const HUD_MINIMAP_WIDTH:int = 160;
    public static const HUD_MINIMAP_HEIGHT:int = 104;

    /** Name + class icon. The art has no dedicated plate, so this sits at
        the top of the empty wood panel below the inventory. */
    public static const HUD_DETAILS_Y:int = 409;

    /**
     * Reserved: the pane art has a fourth groove above the XP bar, kept
     * empty for the adventurer rank / reputation meter. Nothing draws here
     * yet - HUD_BAR_Y covers only the three live meters below it.
     */
    public static const HUD_RANK_BAR_Y:int = 150;

    public static const HUD_BAR_Y:Array = [174, 197, 220];
    public static const HUD_BAR_HEIGHT:int = 14;

    /** Groove interior runs x 27 - 177 on the art. */
    public static const HUD_BAR_X:int = 27;
    public static const HUD_BAR_WIDTH:int = 150;
    public static const HUD_STAT_METERS_Y:int = 174;

    /** Equipment row - four slots. Painted recess runs y 248-280. */
    public static const HUD_EQUIPMENT_Y:int = 248;

    /**
     * Tab strip. Its content sits TAB_TOP_OFFSET (27) below this, and the
     * mediator insets content by a further 7, so the first inventory row lands
     * at 277 + 27 + 7 = 311 - exactly on the painted recess.
     */
    public static const HUD_TAB_STRIP_Y:int = 277;
    /* Tall enough that the potion row (y 444) still fits inside the tab
       content, and the non-inventory panel covers the empty wood area. */
    public static const HUD_TAB_STRIP_HEIGHT:int = 130;

    /** Potion counters along the bottom. */
    public static const HUD_POTIONS_Y:int = 520;

    /**
     * Interact panel (portal name, Locked/Full). Sits near the top of the
     * empty wood area, just under the second inventory row (which ends at
     * 396), rather than sinking to the bottom of the pane.
     */
    public static const HUD_INTERACT_Y:int = 409;

    /**
     * Interact panel (portal names, Change Characters, and a bag's 8 slots).
     *
     * Width is exactly the item grid's width and X is the item grid's X, so a
     * ContainerGrid's 8 slots line up with the inventory columns above it.
     * Panel.WIDTH derives from this - it used to be a hardcoded 188, which
     * silently overflowed the pane when the pane got narrower.
     */
    public static const HUD_INTERACT_X:int = ITEM_GRID_X;
    public static const HUD_INTERACT_WIDTH:int = ITEM_GRID_COLUMNS * ITEM_TILE_WIDTH
                                              + (ITEM_GRID_COLUMNS - 1) * ITEM_GRID_PADDING_X;

    /** Inset the Panel subclasses draw at inside the interact panel. */
    public static const HUD_INTERACT_INSET:int = 6;

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
