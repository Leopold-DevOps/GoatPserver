package com.company.assembleegameclient.ui
{
import com.company.util.AssetLibrary;

import flash.display.BitmapData;

/**
 * Which cell of the "statIcons" image set belongs to which stat.
 *
 * Shared by the stats panel and the item tooltip so the two cannot drift
 * apart - a stat shows the same icon wherever it is listed. Names are the
 * ones Stats.fromId returns and the ones the stats panel's own XML uses.
 */
public class StatIconLibrary
{
   /** Authored cell size of the sheet. */
   public static const SIZE:int = 18;

   // Weapon/item lines, in sheet order.
   public static const SHOTS:int = 0;
   public static const DAMAGE:int = 1;
   public static const RANGE:int = 2;
   public static const RATE_OF_FIRE:int = 3;
   public static const FAME:int = 4;

   private static const BY_NAME:Object = {
      "Defense": 5,
      "Attack": 6,
      "Vitality": 7,
      "Wisdom": 8,
      "Maximum HP": 9,
      "Maximum MP": 10,
      "Speed": 11,
      "Dexterity": 12
   };

   /** Cell for a stat's display name, or -1 when it has no icon. */
   public static function cellForStat(name:String):int
   {
      return BY_NAME.hasOwnProperty(name) ? int(BY_NAME[name]) : -1;
   }

   public static function getIcon(cell:int):BitmapData
   {
      return AssetLibrary.getImageFromSet("statIcons", cell);
   }
}
}
