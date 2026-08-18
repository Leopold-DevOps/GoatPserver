using Shared;
using WorldServer.core.net.stats;
using WorldServer.core.objects;
using WorldServer.core.worlds;

namespace WorldServer.core.commands
{
    public abstract partial class Command
    {
        internal class SetLevel : Command
        {
            public override RankingType RankRequirement => RankingType.Admin;
            public override string CommandName => "setlevel";

            protected override bool Process(Player player, TickTime time, string args)
            {
                if (!int.TryParse(args.Trim(), out var level) || level < 1 || level > 20)
                {
                    player.SendError("Usage: /setlevel <1-20>");
                    return false;
                }

                player.Level = level;
                player.Experience = Player.GetLevelExp(level);
                player.ExperienceGoal = Player.GetExpGoal(level);

                player.SendInfo($"Level set to {level}.");
                return true;
            }
        }

        internal class SetStat : Command
        {
            public override RankingType RankRequirement => RankingType.Admin;
            public override string CommandName => "setstat";

            protected override bool Process(Player player, TickTime time, string args)
            {
                var parts = args.Trim().Split(' ');
                if (parts.Length < 2)
                {
                    player.SendError("Usage: /setstat <0-7|statname> <value>");
                    return false;
                }

                if (!int.TryParse(parts[0], out var index))
                    index = StatsManager.GetStatIndex(parts[0]);

                if (index < 0 || index >= 8)
                {
                    player.SendError($"Unknown stat: {parts[0]}");
                    return false;
                }

                if (!int.TryParse(parts[1], out var value))
                {
                    player.SendError($"Invalid value: {parts[1]}");
                    return false;
                }

                var statInfo = player.GameServer.Resources.GameData.Classes[player.ObjectType].Stats;
                if (value < 0)
                    value = 0;
                if (value > statInfo[index].MaxValue)
                    value = statInfo[index].MaxValue;

                player.Stats.Base[index] = value;

                // keep current hp/mp inside the new caps
                if (index == 0 && player.Health > player.Stats[0])
                    player.Health = player.Stats[0];
                if (index == 1 && player.Mana > player.Stats[1])
                    player.Mana = player.Stats[1];

                player.SendInfo($"{StatsManager.StatIndexToName(index)} set to {value}.");
                return true;
            }
        }

        internal class GiveSlot : Command
        {
            public override RankingType RankRequirement => RankingType.Admin;
            public override string CommandName => "giveslot";

            protected override bool Process(Player player, TickTime time, string args)
            {
                var index = args.IndexOf(' ');
                if (index == -1)
                {
                    player.SendError("Usage: /giveslot <slot> <item>");
                    return false;
                }

                if (!int.TryParse(args.Substring(0, index), out var slot) || slot < 0 || slot >= player.Inventory.Length)
                {
                    player.SendError($"Invalid slot: {args.Substring(0, index)}");
                    return false;
                }

                var name = args.Substring(index + 1);
                var gameData = player.GameServer.Resources.GameData;
                if (!gameData.DisplayIdToObjectType.TryGetValue(name, out ushort objType))
                    if (!gameData.IdToObjectType.TryGetValue(name, out objType))
                    {
                        player.SendError($"unable to find item: {name}!");
                        return false;
                    }

                if (!gameData.Items.ContainsKey(objType))
                {
                    player.SendError($"unable to find item: {name}!");
                    return false;
                }

                player.Inventory[slot] = gameData.Items[objType];
                return true;
            }
        }
    }
}
