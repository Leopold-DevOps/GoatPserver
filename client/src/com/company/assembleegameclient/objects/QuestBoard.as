package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.game.GameSprite;
   
   import kabam.rotmg.quests.QuestModalController;

   /**
    * A world object you walk up to and press Enter on, like a portal, but which
    * opens UI instead of moving you anywhere.
    *
    * It extends Portal purely to inherit the proximity "Enter" plaque and the
    * name plate - Portal.drawEnterButton already handles the interaction range,
    * the plaque's placement above the art, and the hover state, and reproducing
    * that on a plain GameObject would mean duplicating all of it.
    *
    * Server side this is NOT a portal: its XML Class falls through XmlData's
    * switch to a plain ObjectDesc, so it is a static prop with no destination
    * world. Nothing can teleport into it even if a crafted packet tried.
    *
    * MapUserInput routes the Enter click here rather than to usePortal().
    */
   public class QuestBoard extends Portal
   {
      public function QuestBoard(objectXML:XML)
      {
         super(objectXML);
      }

      /**
       * The Enter plaque was clicked while in range - open the board. The
       * plaque test in MapUserInput runs ahead of the player-input gate, so
       * clicking it again while the window is up closes it.
       */
      public function onEnterPressed(gs:GameSprite) : void
      {
         QuestModalController.toggle(gs);
      }
   }
}
