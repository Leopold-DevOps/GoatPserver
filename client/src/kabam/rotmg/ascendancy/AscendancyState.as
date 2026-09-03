package kabam.rotmg.ascendancy {

/**
 * Which nodes are allocated, and which ascendancy was taken.
 *
 * IMPORTANT - this is client-side and in-memory only. Nothing is sent to the
 * server, nothing is saved to the character, and nothing here changes a single
 * player stat. It exists so the tree can be driven and looked at end to end
 * while the interface is being built; persistence and the actual effects are a
 * separate piece of work, and both belong on the server where stats already
 * live (see BoostStatManager).
 *
 * Reloading the client resets everything below.
 */
public class AscendancyState {

    /** node id -> ranks currently put into it. */
    private static var ranks:Object = {};
    /** Which ascendancy the character committed to, or -1 at the gate. */
    private static var chosen:int = -1;

    public static function get chosenPath():int {
        return chosen;
    }

    public static function ranksIn(id:String):int {
        return ranks.hasOwnProperty(id) ? int(ranks[id]) : 0;
    }

    public static function spentIn(tab:int):int {
        var total:int = 0;
        for each (var node:Object in AscendancyData.nodes(tab))
            total += ranksIn(node.id) * costOf(node);
        return total;
    }

    public static function pointsLeft(tab:int):int {
        return AscendancyData.pointsFor(tab) - spentIn(tab);
    }

    public static function costOf(node:Object):int {
        return node.keystone ? AscendancyData.KEYSTONE_COST : 1;
    }

    /**
     * A tab is open if it is the trunk, the ascendancy already taken, or - when
     * nothing has been taken yet - any of the three on offer. Putting the first
     * point into an ascendancy is what commits you, which is the whole point of
     * the gate: the other two close at that moment.
     */
    public static function isTabOpen(tab:int):Boolean {
        if (tab == AscendancyData.ROAD)
            return true;
        return chosen == -1 || chosen == tab;
    }

    /**
     * Tier 0 is always reachable. Past that a tier needs at least one point
     * spent in the tier above it, so the tree is walked rather than cherry
     * picked. Keystones (tier 3) additionally want the tree opened up a bit.
     */
    public static function isTierReachable(tab:int, tier:int):Boolean {
        if (tier == 0)
            return true;
        if (tier == 3)
            return spentIn(tab) >= 4;
        var above:int = 0;
        for each (var node:Object in AscendancyData.nodes(tab))
            if (node.tier == tier - 1)
                above += ranksIn(node.id);
        return above > 0;
    }

    /** A keystone is exclusive - taking one rules the other out. */
    public static function keystoneTaken(tab:int):String {
        for each (var node:Object in AscendancyData.nodes(tab))
            if (node.keystone && ranksIn(node.id) > 0)
                return String(node.id);
        return null;
    }

    public static function canAllocate(tab:int, node:Object):Boolean {
        if (!isTabOpen(tab))
            return false;
        if (ranksIn(node.id) >= int(node.ranks))
            return false;
        if (!isTierReachable(tab, int(node.tier)))
            return false;
        if (node.keystone && keystoneTaken(tab) != null)
            return false;
        return pointsLeft(tab) >= costOf(node);
    }

    public static function allocate(tab:int, node:Object):Boolean {
        if (!canAllocate(tab, node))
            return false;
        ranks[node.id] = ranksIn(node.id) + 1;
        if (tab != AscendancyData.ROAD)
            chosen = tab;
        return true;
    }

    /** Refunds the whole tab rather than single nodes - simpler to reason
        about than unwinding prerequisites one rank at a time. */
    public static function resetTab(tab:int):void {
        for each (var node:Object in AscendancyData.nodes(tab))
            delete ranks[node.id];
        if (tab == chosen)
            chosen = -1;
    }
}
}
