package kabam.rotmg.characters.reskin.control
{
   import com.company.assembleegameclient.objects.Player;
   import com.company.assembleegameclient.util.AnimatedChar;
   import kabam.rotmg.util.Diag;
   import kabam.rotmg.assets.services.CharacterFactory;
   import kabam.rotmg.classes.model.CharacterClass;
   import kabam.rotmg.classes.model.CharacterSkin;
   import kabam.rotmg.classes.model.ClassesModel;
   import kabam.rotmg.game.model.GameModel;
   import kabam.rotmg.messaging.impl.outgoing.Reskin;
   
   public class ReskinHandler
   {
       
      
      [Inject]
      public var model:GameModel;
      
      [Inject]
      public var classes:ClassesModel;
      
      [Inject]
      public var factory:CharacterFactory;
      
      public function ReskinHandler()
      {
         super();
      }
      
      public function execute(reskin:Reskin) : void
      {
         var player:Player = null;
         var skinID:int = 0;
         var charType:CharacterClass = null;
         player = reskin.player || this.model.player;
         skinID = reskin.skinID;
         charType = this.classes.getCharacterClass(player.objectType_);
         var skin:CharacterSkin = charType.skins.getSkin(skinID);
         Diag.at("ReskinHandler: type=0x" + player.objectType_.toString(16)
                 + " skinID=" + skinID
                 + " skin=" + (skin == null ? "NULL" : "ok")
                 + " template=" + (skin == null || skin.template == null ? "NULL"
                         : "'" + skin.template.file + "':" + skin.template.index));

         /* A class with no skin registered - a newly added one, say - yields a
            null skin here. Assigning a null player.skin while clearing
            isDefaultAnimatedChar used to guarantee a crash on the next frame,
            because Player.draw() then calls makeSkinTexture() which
            dereferences it. Keep the class's own animated character instead. */
         var animated:AnimatedChar = (skin == null || skin.template == null)
                 ? null
                 : this.factory.makeCharacter(skin.template);

         if (animated == null)
         {
            Diag.at("ReskinHandler: no skin for type 0x" + player.objectType_.toString(16)
                    + ", keeping default animated char");
            player.skinId = 0;
            player.isDefaultAnimatedChar = true;
            return;
         }

         player.skinId = skinID;
         player.skin = animated;
         player.isDefaultAnimatedChar = false;
         Diag.at("ReskinHandler: applied skin ok");
      }
   }
}
