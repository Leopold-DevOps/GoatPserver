package kabam.rotmg.constants {

/**
 * Adventurer rank tiers - the label and colour shown under every player.
 *
 * The server only ever sends an integer (StatData.ADVENTURER_RANK); the label
 * and colour live here so the presentation can change without a protocol or
 * server change. Rank 0 is where everyone starts.
 *
 * Ranks above the end of the table fall back to the last entry rather than
 * erroring, so the server can hand out a higher rank before the art/naming
 * for it is decided.
 */
public class AdventurerRank {

    public static const BEGINNER:int = 0;

    private static const LABELS:Array = [
        "Beginner",
        "Rank I",
        "Rank II",
        "Rank III",
        "Rank IV",
        "Rank V"
    ];

    /* Distinct hues, readable against both the grass and stone of the Nexus.
       Roughly: grey -> green -> blue -> purple -> orange -> gold. */
    private static const COLORS:Array = [
        0x9CA3AF,
        0x4ADE80,
        0x38BDF8,
        0xA855F7,
        0xFB923C,
        0xFACC15
    ];

    public static function get count():int {
        return LABELS.length;
    }

    private static function clamp(rank:int):int {
        if (rank < 0) {
            return 0;
        }
        return rank >= LABELS.length ? LABELS.length - 1 : rank;
    }

    public static function label(rank:int):String {
        return LABELS[clamp(rank)];
    }

    public static function color(rank:int):uint {
        return uint(COLORS[clamp(rank)]);
    }
}
}
