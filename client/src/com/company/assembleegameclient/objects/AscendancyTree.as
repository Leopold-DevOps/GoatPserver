package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.game.GameSprite;

   import kabam.rotmg.ascendancy.AscendancyModalController;

   /**
    * The ascendancy tree landmark in the Nexus.
    *
    * Extends Portal for the same reason QuestBoard does: Portal already draws
    * the proximity Enter plaque and the name plate, handles interaction range
    * and hover, and reproducing that on a plain GameObject would duplicate all
    * of it. Server side this is still a static prop with no destination world,
    * and MapUserInput routes the press here instead of to usePortal().
    */
   public class AscendancyTree extends Portal
   {
      public function AscendancyTree(objectXML:XML)
      {
         super(objectXML);
      }

      public function onEnterPressed(gs:GameSprite) : void
      {
         AscendancyModalController.toggle(gs);
      }
   }
}
