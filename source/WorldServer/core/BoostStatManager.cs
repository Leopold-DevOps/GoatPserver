using Shared.resources;
using System;
using System.Collections.Generic;
using System.Linq;
using WorldServer.core.objects;
using WorldServer.utils;
using WorldServer.core.net.stats;

namespace WorldServer.core
{
    internal class BoostStatManager
    {
        public ActivateBoost[] ActivateBoost;
        private int[] _boost;
        private StatTypeValue<int>[] _boostSV;
        private StatsManager _parent;
        private Player _player;
        /** Conditions currently applied because of an equipped item, so an
            item that stops being equipped has its condition removed rather
            than left on permanently. Reconciled fresh every recompute in
            ApplyEquipBonus - see the class comment on Item.ActivateOnEquipConditions. */
        private readonly HashSet<ConditionEffectIndex> _equipConditions = new HashSet<ConditionEffectIndex>();

        public BoostStatManager(StatsManager parent)
        {
            _parent = parent;
            _player = parent.Owner;
            _boost = new int[StatsManager.NumStatTypes];
            _boostSV = new StatTypeValue<int>[_boost.Length];

            for (var i = 0; i < _boostSV.Length; i++)
                _boostSV[i] = new StatTypeValue<int>(_player, StatsManager.GetBoostStatType(i), _boost[i], i != 0 && i != 1);

            ActivateBoost = new ActivateBoost[_boost.Length];
            for (var i = 0; i < ActivateBoost.Length; i++)
                ActivateBoost[i] = new ActivateBoost();

            ReCalculateValues();
        }

        public int this[int index] => _boost[index];

        protected internal void ReCalculateValues()
        {
            for (var i = 0; i < _boost.Length; i++)
                _boost[i] = 0;

            ApplyEquipBonus();
            ApplyActivateBonus();
            IncrementStatBoost();

            for (var i = 0; i < _boost.Length; i++)
                _boostSV[i].SetValue(_boost[i]);
        }

        private void ApplyActivateBonus()
        {
            for (var i = 0; i < ActivateBoost.Length; i++)
            {
                // set boost
                var b = ActivateBoost[i].GetBoost();
                _boost[i] += b;

                // set condition icon

                var effect = (ConditionEffectIndex)((int)ConditionEffectIndex.HpBoost + i);
                var haveCondition = _player.HasConditionEffect(effect);
                if (b > 0)
                {
                    if (!haveCondition)
                        _player.ApplyPermanentConditionEffect(effect);
                }
                else
                {
                    if (haveCondition)
                        _player.RemoveCondition(effect);
                }
            }
        }

        private void ApplyEquipBonus()
        {
            var desiredConditions = new HashSet<ConditionEffectIndex>();

            for (var i = 0; i < 4; i++)
            {
                if (_player.Inventory[i] == null)
                    continue;

                foreach (var b in _player.Inventory[i].ActivateOnEquips)
                    IncrementBoost((StatDataType)b.Key, b.Value);
                foreach (var c in _player.Inventory[i].ActivateOnEquipConditions)
                    desiredConditions.Add(c);
            }

            for (var i = 20; i < 28; i++)
            {
                if (_player.Inventory[i] == null || _player.Inventory[i].SlotType != 26)
                    continue;
                foreach (var b in _player.Inventory[i].ActivateOnEquips)
                    IncrementBoost((StatDataType)b.Key, b.Value);
                foreach (var c in _player.Inventory[i].ActivateOnEquipConditions)
                    desiredConditions.Add(c);
            }

            // Reconcile against what is currently applied: this is what stops
            // an unequipped item's condition from staying on forever, and stops
            // a re-equip from redundantly reapplying one that never left.
            foreach (var effect in desiredConditions)
            {
                if (_equipConditions.Add(effect))
                    _player.ApplyPermanentConditionEffect(effect);
            }
            _equipConditions.RemoveWhere(effect =>
            {
                if (desiredConditions.Contains(effect))
                    return false;
                _player.RemoveCondition(effect);
                return true;
            });

            // Deliberately last: the health percentage below has to be measured
            // against the max HP the player actually has, including any bonus
            // just added by the loops above (the bag grants +100 itself), not
            // the base pool.
            ApplyHpTierBoosts();
        }

        /**
         * Apply the health band that currently matches, for any equipped item
         * that declares bands. See Item.HpTierBoost.
         *
         * These are re-evaluated once a second from Player.PassiveEffects while
         * such an item is equipped - a recompute is otherwise only triggered by
         * an inventory change, so nothing would notice health moving.
         */
        private void ApplyHpTierBoosts()
        {
            var maxHp = _parent.Base[0] + _boost[0];
            if (maxHp <= 0)
                return;

            var percent = _player.Health * 100 / maxHp;
            if (percent > 100)
                percent = 100;

            for (var i = 0; i < 4; i++)
            {
                var item = _player.Inventory[i];
                if (item == null || item.HpTierBoosts == null)
                    continue;

                foreach (var tier in item.HpTierBoosts)
                {
                    if (percent < tier.MinPercent || percent > tier.MaxPercent)
                        continue;

                    foreach (var s in tier.Stats)
                        IncrementBoost((StatDataType)s.Key, s.Value);
                }
            }
        }

        private void FixedStat(StatDataType stat, int value)
        {
            var i = StatsManager.GetStatIndex(stat);
            _boost[i] = value - _parent.Base[i];
        }

        private int IncreasePercentage(int percentageToIncrease, int stat)
        {
            int percentage = percentageToIncrease;
            var result = percentage * _parent.Base[stat] / 100;
            return result;
        }

        public void IncrementBoost(StatDataType stat, int amount)
        {
            var i = StatsManager.GetStatIndex(stat);

            if (_parent.Base[i] + amount < 1)
                amount = i == 0 ? -_parent.Base[i] + 1 : -_parent.Base[i];

            _boost[i] += amount;
        }

        private void IncrementStatBoost()
        {
            if (_player == null || _player.Client == null || _player.Client.Account == null)
                return;

            for (var a = 0; a < 8; a++)
            {
                if (a >= 7)
                    a = 7;

                if (a >= 8)
                    return;
                if (_player.Client.Account.SetBaseStat > 0)
                    _boost[a] += a < 2 ? _player.Client.Account.SetBaseStat * 5 : _player.Client.Account.SetBaseStat;
            }
        }
    }
}
