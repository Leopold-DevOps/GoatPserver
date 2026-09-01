package com.company.assembleegameclient.appengine
{
   import com.company.assembleegameclient.util.FameUtil;
   
   public class CharacterStats
   {
       
      
      public var charStatsXML_:XML;
      
      public function CharacterStats(charStatsXML:XML)
      {
         super();
         this.charStatsXML_ = charStatsXML;
      }
      
      /* All three read charStatsXML_, which is whatever the caller passed -
         including null. Callers null-check the CharacterStats object but not
         its XML, so guard here rather than at every call site. */
      public function bestLevel() : int
      {
         return this.charStatsXML_ == null ? 0 : int(this.charStatsXML_.BestLevel);
      }
      
      public function bestFame() : int
      {
         return this.charStatsXML_ == null ? 0 : int(this.charStatsXML_.BestFame);
      }
      
      public function numStars() : int
      {
         return this.charStatsXML_ == null ? 0 : FameUtil.numStars(int(this.charStatsXML_.BestFame));
      }
   }
}
