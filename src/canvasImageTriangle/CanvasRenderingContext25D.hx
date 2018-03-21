package canvasImageTriangle;
// By Thatcher Ulrich http://tulrich.com 2009
//
// This source code has been donated to the Public Domain.  Do
// whatever you want with it.  Use at your own risk.
//
// ported to Haxe by Nanjazal 20 March 2018
import js.html.CanvasRenderingContext2D;
import js.html.Image;
import js.html.ImageElement;
@:forward
abstract CanvasRenderingContext25D( CanvasRenderingContext2D ) from CanvasRenderingContext2D to CanvasRenderingContext2D {
    public inline 
    function new( ctx: CanvasRenderingContext2D ){
        this = ctx;
    }
    public 
    function drawTriangle( im:  ImageElement
                         , ax:  Float, ay:  Float, bx:  Float, by:  Float, cx:  Float, cy:  Float
                         , asx: Float, asy: Float, bsx: Float, bsy: Float, csx: Float, csy: Float ) {
        this.save();
        // Clip the output to the on-screen triangle boundaries.
        this.beginPath();
        this.moveTo( ax, ay ); // ax, ay = x0, y0    asx, asy = sx0, sy0
        this.lineTo( bx, by ); // bx, by = x1, y1    bsx, bsy = sx1, sy1
        this.lineTo( cx, cy ); // cx, cy = x2, y2    csx, csy = sx2, sy2
        this.closePath();
      //ctx.stroke();//xxxxxxx for wireframe
        this.clip();

        /*
        ctx.transform(m11, m12, m21, m22, dx, dy) sets the context transform matrix.

        The context matrix is:

        [ m11 m21 dx ]
        [ m12 m22 dy ]
        [  0   0   1 ]

        Coords are column vectors with a 1 in the z coord, so the transform is:
        x_out = m11 * x + m21 * y + dx;
        y_out = m12 * x + m22 * y + dy;

        From Maxima, these are the transform values that map the source
        coords to the dest coords:

        sy0 (x2 - x1) - sy1 x2 + sy2 x1 + (sy1 - sy2) x0
        [m11 = - -----------------------------------------------------,
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0

        sy1 y2 + sy0 (y1 - y2) - sy2 y1 + (sy2 - sy1) y0
        m12 = -----------------------------------------------------,
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0

        sx0 (x2 - x1) - sx1 x2 + sx2 x1 + (sx1 - sx2) x0
        m21 = -----------------------------------------------------,
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0

        sx1 y2 + sx0 (y1 - y2) - sx2 y1 + (sx2 - sx1) y0
        m22 = - -----------------------------------------------------,
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0

        sx0 (sy2 x1 - sy1 x2) + sy0 (sx1 x2 - sx2 x1) + (sx2 sy1 - sx1 sy2) x0
        dx = ----------------------------------------------------------------------,
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0

        sx0 (sy2 y1 - sy1 y2) + sy0 (sx1 y2 - sx2 y1) + (sx2 sy1 - sx1 sy2) y0
        dy = ----------------------------------------------------------------------]
        sx0 (sy2 - sy1) - sx1 sy2 + sx2 sy1 + (sx1 - sx2) sy0
        */

        // TODO: eliminate common subexpressions. Eliminated some..
        var denom = asx * (csy - bsy) - bsx * csy + csx * bsy + (bsx - csx) * asy;
        return if ( denom == 0 ){
            null;
        } else {
            var bcy = by - cy; // byMcy
            var cbx = cx - bx; // cxMbx
            var bcsy = bsy - csy;
            var bcsx = bsx - csx;
            var m11 = - ( asy * cbx - bsy * cx + csy * bx + bcsy * ax ) / denom;
            
            var m12 = ( bsy * cy + asy * bcy - csy * by - bcsy * ay ) / denom;
            
            var m21 = ( asx * cbx - bsx * cx + csx * bx + bcsx * ax ) / denom;
            
            var m22 = - ( bsx * cy + asx * bcy - csx * by - bcsx * ay ) / denom;
            
            var xcbbc = csx * bsy - bsx * csy;
            var dx = ( asx * (csy * bx - bsy * cx ) + asy *( bsx * cx - csx * by ) + xcbbc * ax) / denom;
            var dy = ( asx * (csy * by - bsy * cy ) + asy *( bsx * cx - csx * by ) + xcbbc * ay) / denom;
            this.transform( m11, m12, m21, m22, dx, dy );
            // Draw the whole image.  Transform and clip will map it onto the
            // correct output triangle.
            //
            // TODO: figure out if drawImage goes faster if we specify the rectangle that
            // bounds the source coords.
            this.drawImage( im, 0, 0 );
            this.restore();
         }
    }
}