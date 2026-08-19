using Shared;
using WorldServer.core.objects;
using WorldServer.core.worlds;

namespace WorldServer.core.commands
{
    public abstract partial class Command
    {
        /// <summary>
        /// Sets a player's adventurer rank.
        ///
        /// Temporary: ranks are meant to be earned through reputation, which
        /// does not exist yet. This exists so the tiers can be seen and tuned
        /// in the meantime, and should be kept admin-only.
        ///
        ///   /advrank 2          - set your own rank
        ///   /advrank Goat 2     - set another player's rank
        /// </summary>
        internal class AdventurerRankCommand : Command
        {
            public override RankingType RankRequirement => RankingType.Admin;
            public override string CommandName => "advrank";

            protected override bool Process(Player player, TickTime time, string args)
            {
                if (string.IsNullOrWhiteSpace(args))
                {
                    player.SendInfo("Usage: /advrank [player] <rank>");
                    return false;
                }

                var parts = args.Trim().Split(' ');
                var target = player;
                string rankText;

                if (parts.Length == 1)
                    rankText = parts[0];
                else
                {
                    var name = string.Join(" ", parts, 0, parts.Length - 1);
                    rankText = parts[parts.Length - 1];

                    target = null;
                    foreach (var p in player.World.Players.Values)
                        if (string.Equals(p.Name, name, System.StringComparison.OrdinalIgnoreCase))
                        {
                            target = p;
                            break;
                        }

                    if (target == null)
                    {
                        player.SendError($"Player '{name}' not found in this world.");
                        return false;
                    }
                }

                if (!int.TryParse(rankText, out var rank) || rank < 0)
                {
                    player.SendError($"'{rankText}' is not a valid rank.");
                    return false;
                }

                target.AdventurerRank = rank;
                player.SendInfo($"{target.Name} is now adventurer rank {rank}.");
                if (target != player)
                    target.SendInfo($"Your adventurer rank is now {rank}.");
                return true;
            }
        }
    }
}
