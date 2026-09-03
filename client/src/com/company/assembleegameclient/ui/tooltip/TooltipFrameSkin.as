package com.company.assembleegameclient.ui.tooltip
{
import com.company.util.BitmapUtil;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Matrix;

import kabam.rotmg.assets.EmbeddedAssets;

/**
 * Paints the ornate tooltip panel at any height.
 *
 * The art is stretched vertically only: the source has ornate corner
 * flourishes at top and bottom, and a gem centred on each side edge, none of
 * which survive being scaled. So it is cut into bands - a fixed top cap, a
 * fixed bottom cap, a short clean middle band with no ornament that is the
 * only thing stretched, and the pair of side gems, drawn once at the
 * vertical centre at their natural size.
 *
 * Horizontally the caps do scale, but the frame is authored at the width the
 * tooltip actually uses (its interior is 229px against a MAX_WIDTH of 230),
 * so that factor stays at or near 1 and the ornaments are not visibly
 * distorted.
 */
public class TooltipFrameSkin
{
   /** Width the bands were authored at. */
   public static const FRAME_WIDTH:int = 272;
   /** Border thickness, so content can be inset clear of the art. */
   public static const BORDER:int = 21;

   private static const TOP_H:int = 66;
   private static const BOTTOM_H:int = 65;
   private static const TILE_Y:int = 131;
   private static const TILE_H:int = 10;
   private static const GEMS_Y:int = 141;
   private static const GEMS_H:int = 28;

   private static var topCap:BitmapData;
   private static var bottomCap:BitmapData;
   private static var tile:BitmapData;
   private static var gems:BitmapData;

   private static function init():void
   {
      if (topCap != null)
         return;
      var sheet:BitmapData = new EmbeddedAssets.tooltipFrame().bitmapData;
      topCap = BitmapUtil.cropToBitmapData(sheet, 0, 0, FRAME_WIDTH, TOP_H);
      bottomCap = BitmapUtil.cropToBitmapData(sheet, 0, TOP_H, FRAME_WIDTH, BOTTOM_H);
      tile = BitmapUtil.cropToBitmapData(sheet, 0, TILE_Y, FRAME_WIDTH, TILE_H);
      gems = BitmapUtil.cropToBitmapData(sheet, 0, GEMS_Y, FRAME_WIDTH, GEMS_H);
   }

   /** One ornate divider bar, at the width the art was authored for. */
   public static function makeDivider():Bitmap
   {
      return new Bitmap(new EmbeddedAssets.tooltipDivider().bitmapData);
   }

   /**
    * Paint the frame filling exactly the rect (x, y, w, h) - the OUTER edge
    * of the art, so the caller decides how much room to leave around its
    * content on each side.
    */
   public static function draw(g:Graphics, x:Number, y:Number, w:Number, h:Number):void
   {
      init();

      var frameW:Number = w;
      var frameH:Number = h;
      // The two caps cannot overlap; a very short tooltip just gets a taller
      // frame rather than a squashed one.
      if (frameH < TOP_H + BOTTOM_H)
         frameH = TOP_H + BOTTOM_H;

      var sx:Number = frameW / FRAME_WIDTH;
      var left:Number = x;
      var top:Number = y;
      var innerH:Number = frameH - TOP_H - BOTTOM_H;

      // Stretched middle first, then the caps over it, then the gems.
      if (innerH > 0)
         paint(g, tile, left, top + TOP_H, sx, innerH / TILE_H, frameW, innerH);
      paint(g, topCap, left, top, sx, 1, frameW, TOP_H);
      paint(g, bottomCap, left, top + frameH - BOTTOM_H, sx, 1, frameW, BOTTOM_H);
      paint(g, gems, left, top + (frameH - GEMS_H) / 2, sx, 1, frameW, GEMS_H);
   }

   private static function paint(g:Graphics, bmp:BitmapData, x:Number, y:Number,
                                 sx:Number, sy:Number, w:Number, h:Number):void
   {
      var m:Matrix = new Matrix();
      m.scale(sx, sy);
      m.translate(x, y);
      g.beginBitmapFill(bmp, m, false, true);
      g.drawRect(x, y, w, h);
      g.endFill();
   }
}
}
