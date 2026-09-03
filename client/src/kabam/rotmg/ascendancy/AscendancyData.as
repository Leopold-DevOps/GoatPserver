package kabam.rotmg.ascendancy {

/**
 * The tree definition: what the nodes are, what they cost, and what they say.
 *
 * Deliberately data rather than layout. Every node carries the tier and column
 * it sits in, so the renderer lays out a grid from this - retuning the tree, or
 * swapping placeholder shapes for real art later, never means editing drawing
 * code.
 *
 * Effects are display strings. Nothing here is applied to the player yet; see
 * the note on AscendancyState.
 */
public class AscendancyData {

    public static const ROAD:int = 0;
    public static const CARNIFEX:int = 1;
    public static const SENTINEL:int = 2;
    public static const DAWNBEARER:int = 3;

    public static const TAB_NAMES:Array = ["The Road", "Carnifex", "Iron Sentinel", "Dawnbearer"];
    /** Short forms, for the panel's narrow left rail. */
    public static const TAB_SHORT:Array = ["The Road", "Carnifex", "Sentinel", "Dawnbearer"];
    public static const TAB_COLORS:Array = [0x3B9EFF, 0xC6484C, 0x7FA3C4, 0xE8A33D];
    public static const TAB_BLURB:Array = [
        "The shared trunk - everyone walks this before they are anything.",
        "Wound-fed. Every threshold you fall through makes you deadlier.",
        "Anchored. Standing still is a build; Defense becomes offense.",
        "Radiant. Strongest untouched, and desperate to stay that way."
    ];

    /** Points granted for the trunk, and for whichever ascendancy is taken. */
    public static const ROAD_POINTS:int = 12;
    public static const ASCENDANCY_POINTS:int = 9;
    public static const KEYSTONE_COST:int = 2;

    /**
     * A node is {id, name, ranks, tier, col, effect, keystone}.
     * Tiers 0-2 are the three grid rows; tier 3 is the keystone row.
     */
    public static function nodes(tab:int):Array {
        switch (tab) {
            case ROAD: return ROAD_NODES;
            case CARNIFEX: return CARNIFEX_NODES;
            case SENTINEL: return SENTINEL_NODES;
            case DAWNBEARER: return DAWN_NODES;
        }
        return [];
    }

    public static function pointsFor(tab:int):int {
        return tab == ROAD ? ROAD_POINTS : ASCENDANCY_POINTS;
    }

    private static const ROAD_NODES:Array = [
        {id:"whetstone", name:"Whetstone", ranks:3, tier:0, col:0, effect:"+2 Attack per rank"},
        {id:"padded", name:"Padded Lining", ranks:3, tier:0, col:1, effect:"+2 Defense per rank"},
        {id:"boots", name:"Roadworn Boots", ranks:2, tier:0, col:2, effect:"+2 Speed per rank"},
        {id:"steady", name:"Steady Hand", ranks:3, tier:1, col:0, effect:"+2 Dexterity per rank"},
        {id:"rations", name:"Rations", ranks:3, tier:1, col:1, effect:"+20 Max HP per rank"},
        {id:"wind", name:"Second Wind", ranks:2, tier:1, col:2, effect:"Below 50% HP: +5 Vitality per rank"},
        {id:"grip", name:"Sure Grip", ranks:3, tier:2, col:0, effect:"+3% Rate of Fire per rank"},
        {id:"reach", name:"Reach", ranks:2, tier:2, col:1, effect:"+0.15 Range per rank"},
        {id:"resolve", name:"Resolve", ranks:1, tier:2, col:2, effect:"Above 90% HP: +8 Attack. Below 25% HP: +15 Defense."}
    ];

    private static const CARNIFEX_NODES:Array = [
        {id:"bloodletting", name:"Bloodletting", ranks:1, tier:0, col:0, effect:"On hitting an enemy, 4% chance of Berserk for 1.5s"},
        {id:"stomach", name:"Iron Stomach", ranks:1, tier:0, col:1, effect:"+40 Max HP, -3 Vitality"},
        {id:"reckless", name:"Reckless Swing", ranks:1, tier:0, col:2, effect:"+12 Attack, -6 Defense"},
        {id:"tide", name:"Crimson Tide", ranks:1, tier:1, col:0, effect:"Below 60% HP: +12 Attack"},
        {id:"rhythm", name:"Butchers Rhythm", ranks:1, tier:1, col:1, effect:"Each hit within 2s: +2 Dexterity, up to 5 stacks"},
        {id:"threshold", name:"Pain Threshold", ranks:1, tier:1, col:2, effect:"Struck below 40% HP: Armored 2s, 10s cooldown"},
        {id:"feast", name:"Sanguine Feast", ranks:1, tier:2, col:0, effect:"Killing an enemy restores 4% Max HP"},
        {id:"dread", name:"Dread Presence", ranks:1, tier:2, col:1, effect:"Permanent Damaging while below 75% HP"},
        {id:"executioner", name:"Executioner", ranks:1, tier:2, col:2, effect:"+30% damage to enemies below 25% HP"},
        {id:"crown", name:"The Red Crown", ranks:1, tier:3, col:0, keystone:true, effect:"Cannot be healed above 60% Max HP. Permanent Berserk and Damaging."},
        {id:"rites", name:"Last Rites", ranks:1, tier:3, col:1, keystone:true, effect:"Below 20% HP: Invincible 2s and +50 Attack for 5s. Once per 60s."}
    ];

    private static const SENTINEL_NODES:Array = [
        {id:"tower", name:"Tower Stance", ranks:1, tier:0, col:0, effect:"+15 Defense"},
        {id:"anchored", name:"Anchored", ranks:1, tier:0, col:1, effect:"After 1s without moving: +10 Defense"},
        {id:"riposte", name:"Riposte", ranks:1, tier:0, col:2, effect:"On being hit, 8% chance of +10 Attack for 3s"},
        {id:"bulwark", name:"Bulwark", ranks:1, tier:1, col:0, effect:"Permanent Armored while above 75% HP"},
        {id:"weight", name:"Weight of Steel", ranks:1, tier:1, col:1, effect:"Attack equal to 25% of Defense, capped at +25"},
        {id:"unyielding", name:"Unyielding", ranks:1, tier:1, col:2, effect:"Immune to Slowed and Paralyzed"},
        {id:"counter", name:"Counterweight", ranks:1, tier:2, col:0, effect:"Each hit taken: +3 Defense for 4s, up to 6 stacks"},
        {id:"vigil", name:"Vigil", ranks:1, tier:2, col:1, effect:"Each second stationary, restore 1% Max HP"},
        {id:"wall", name:"Wall of the Faithful", ranks:1, tier:2, col:2, effect:"Allies within 3 tiles gain +8 Defense"},
        {id:"bastion", name:"The Great Bastion", ranks:1, tier:3, col:0, keystone:true, effect:"Stationary: +40 Defense and Armored. Moving: -15 Defense."},
        {id:"oath", name:"Oath of the Gate", ranks:1, tier:3, col:1, keystone:true, effect:"Below 35% HP: Invincible 1.5s and a shockwave. Once per 45s."}
    ];

    private static const DAWN_NODES:Array = [
        {id:"consecrated", name:"Consecrated Steel", ranks:1, tier:0, col:0, effect:"Above 75% HP: +10 Attack"},
        {id:"litany", name:"Litany", ranks:1, tier:0, col:1, effect:"+8 Wisdom, +8 Vitality"},
        {id:"hands", name:"Lay on Hands", ranks:1, tier:0, col:2, effect:"Using your ability also restores 8% Max HP"},
        {id:"aura", name:"Radiant Aura", ranks:1, tier:1, col:0, effect:"Allies within 4 tiles gain +6 Attack"},
        {id:"grace", name:"Grace", ranks:1, tier:1, col:1, effect:"At full HP: +12 Speed and +12 Dexterity"},
        {id:"absolution", name:"Absolution", ranks:1, tier:1, col:2, effect:"On being hit, 10% chance to cleanse a condition"},
        {id:"sanctuary", name:"Sanctuary", ranks:1, tier:2, col:0, effect:"Permanent Armored while above 90% HP"},
        {id:"dawnlight", name:"Dawnlight", ranks:1, tier:2, col:1, effect:"Each second, restore 0.5% Max HP to you and nearby allies"},
        {id:"vow", name:"Zealots Vow", ranks:1, tier:2, col:2, effect:"At exactly 100% HP: +20 Attack"},
        {id:"sun", name:"The Risen Sun", ranks:1, tier:3, col:0, keystone:true, effect:"At full HP: Berserk and Damaging. Any damage strips both until you heal to full."},
        {id:"martyr", name:"Martyrs Light", ranks:1, tier:3, col:1, keystone:true, effect:"Lethal damage instead leaves you at 40% HP and heals nearby allies. Once per 90s."}
    ];
}
}
