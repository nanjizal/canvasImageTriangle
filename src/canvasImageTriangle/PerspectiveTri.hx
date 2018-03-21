package canvasImageTriangle;
import js.html.ImageElement;
import canvasImageTriangle.AffineMatrix;
import canvasImageTriangle.CanvasRenderingContext25D;
import canvasImageTriangle.ContextHandler;
import canvasImageTriangle.Point;
import canvasImageTriangle.Point3D;
import canvasImageTriangle.Vertex;

typedef Options = {     draw_backfaces:    Bool
                    ,   whiteout_alpha:    Float
                    ,   wireframe:         Bool
                    ,   subdivide_factor:  Float
                    ,   nonadaptive_depth: Int }

class PerspectiveTri {
    var surface:    CanvasRenderingContext25D;
    var image:      ImageElement;
    var options:    Options;
    var MIN_Z               = 0.05;
    var draw_wireframe      = false;
    public
    function new( surface_: CanvasRenderingContext25D, image_: ImageElement, options_: Options ){
        surface = surface_;
        image   = image_;
        options = options_;
    }
    public
    function render( tverts: Array<Vertex>, width: Float, height: Float ){
        // Clear with white.
        surface.globalAlpha = options.whiteout_alpha;
        surface.fillStyle = '#FFFFFF';
        surface.fillRect( 0, 0, width, height );
        surface.globalAlpha = 1;
        var depth = options.nonadaptive_depth;
        draw( tverts[ 0 ], tverts[ 1 ], tverts[ 2 ], depth );
        draw( tverts[ 0 ], tverts[ 2 ], tverts[ 3 ], depth );
        if( options.wireframe ){
            surface.globalAlpha = 0.3;
            surface.fillRect( 0, 0, width, height );
            draw_wireframe = true;
            surface.globalAlpha = 1;
            draw( tverts[ 0 ], tverts[ 1 ], tverts[ 2 ], depth );
            draw( tverts[ 0 ], tverts[ 2 ], tverts[ 3 ], depth );
            draw_wireframe = false;
        }
    }
    // NOT IDEAL HERE?
    // Return the point between two points, also bisect the texture coords.
    public static inline
    function bisect( p: Vertex, q: Vertex ): Vertex {
        var p = {   x: ( p.x + q.x ) / 2,
                    y: ( p.y + q.y ) / 2,
                    z: ( p.z + q.z ) / 2,
                    u: ( p.u + q.u ) / 2,
                    v: ( p.v + q.v ) / 2 };
        return p;
    }
    // for debugging
    function unclippedSubX( a: Vertex, tv0: Point3D
                          , b: Vertex, tv1: Point3D
                          , c: Vertex, tv2: Point3D ){
        surface.beginPath();
        surface.moveTo( tv0.x, tv0.y );
        surface.lineTo( tv1.x, tv1.y );
        surface.lineTo( tv2.x, tv2.y );
        surface.lineTo( tv0.x, tv0.y );
        surface.stroke();
    }
    function unclippedSub( a: Vertex, tv0: Point3D
                                           , b: Vertex, tv1: Point3D
                                           , c: Vertex, tv2: Point3D
                                           , ?depth_count: Int = null ){
        var edgelen01 = Math.abs( tv0.x - tv1.x ) + Math.abs( tv0.y - tv1.y );
        var edgelen12 = Math.abs( tv1.x - tv2.x ) + Math.abs( tv1.y - tv2.y );
        var edgelen20 = Math.abs( tv2.x - tv0.x ) + Math.abs( tv2.y - tv0.y );
        var zdepth01  = Math.abs( a.z - b.z );
        var zdepth12  = Math.abs( b.z - c.z );
        var zdepth20  = Math.abs( c.z - a.z );
        var factor = options.subdivide_factor;
        var subdiv = ( ( edgelen01 * zdepth01 > factor ) ? 1 : 0 ) +
                     ( ( edgelen12 * zdepth12 > factor ) ? 2 : 0 ) +
                     ( ( edgelen20 * zdepth20 > factor ) ? 4 : 0 );
        var truthy = !( depth_count == 0 && depth_count == null );
        if( truthy ){
            depth_count--;
            if( depth_count == 0 ){
                subdiv = 0;
            } else {
                subdiv = 7;
            }
        }
        if( subdiv == 0 ){
            if( draw_wireframe ) {
                  surface.beginPath();
                  surface.moveTo( tv0.x, tv0.y );
                  surface.lineTo( tv1.x, tv1.y );
                  surface.lineTo( tv2.x, tv2.y );
                  surface.lineTo( tv0.x, tv0.y );
                  surface.stroke();
            } else {
                  surface.drawTriangle( image,
                                        tv0.x, tv0.y,
                                        tv1.x, tv1.y,
                                        tv2.x, tv2.y,
                                        a.u, a.v,
                                        b.u, b.v,
                                        c.u, c.v);
            }
            return;
        }
        // Need to subdivide.  This code could be more optimal, but I'm
        // trying to keep it reasonably short.
        var v01  = bisect( a, b );
        var tv01 = Point3D.projectPoint( v01 );
        var v12  = bisect( b, c );
        var tv12 = Point3D.projectPoint( v12 );
        var v20  = bisect( c, a );
        var tv20 = Point3D.projectPoint( v20 );
        switch( subdiv ){
            case 1:
                // split along v01-v2
                unclippedSub( a, tv0, v01, tv01, c, tv2);
                unclippedSub( v01, tv01, b, tv1, c, tv2);
            case 2:
                // split along v0-v12
                unclippedSub( a, tv0, b, tv1, v12, tv12);
                unclippedSub( a, tv0, v12, tv12, c, tv2);
            case 3:
                // split along v01-v12
                unclippedSub( a, tv0, v01, tv01, v12, tv12);
                unclippedSub( a, tv0, v12, tv12, c, tv2);
                unclippedSub( v01, tv01, b, tv1, v12, tv12);
            case 4:
                // split along v1-v20
                unclippedSub( a, tv0, b, tv1, v20, tv20 );
                unclippedSub( b, tv1, c, tv2, v20, tv20 );
            case 5:
                // split along v01-v20
                unclippedSub( a, tv0, v01, tv01, v20, tv20);
                unclippedSub( b, tv1, c, tv2, v01, tv01);
                unclippedSub( c, tv2, v20, tv20, v01, tv01);
            case 6:
                // split along v12-v20
                unclippedSub( a, tv0, b, tv1, v20, tv20);
                unclippedSub( b, tv1, v12, tv12, v20, tv20);
                unclippedSub( v12, tv12, c, tv2, v20, tv20);
            default: // 7
                unclippedSub( a, tv0, v01, tv01, v20, tv20, depth_count);
                unclippedSub( b, tv1, v12, tv12, v01, tv01, depth_count);
                unclippedSub( c, tv2, v20, tv20, v12, tv12, depth_count);
                unclippedSub( v01, tv01, v12, tv12, v20, tv20, depth_count);
        }
        return;
    }
    public inline
    function unclipped( a: Vertex, b: Vertex, c: Vertex, ?depth_count: Int) {
        var tv0 = Point3D.projectPoint( a );
        var tv1 = Point3D.projectPoint( b );
        var tv2 = Point3D.projectPoint( c );
        unclippedSub( a, tv0, b, tv1, c, tv2, depth_count );
    }
    // Given an edge that crosses the z==MIN_Z plane, return the
    // intersection of the edge with z==MIN_Z.
    public inline
    function clip_line( p: Vertex, q: Vertex ): Vertex {
        var f = ( MIN_Z - p.z ) / ( q.z - p.z );
        return {    x: p.x + ( q.x - p.x ) * f
                ,   y: p.y + ( q.y - p.y ) * f
                ,   z: p.z + ( q.z - p.z ) * f
                ,   u: p.u + ( q.u - p.u ) * f
                ,   v: p.v + ( q.v - p.v ) * f
        };
    }
    // Draw a perspective-corrected textured triangle, subdividing as
    // necessary for clipping and texture mapping.
    public inline
    function conventionalClipping( a: Vertex, b: Vertex, c: Vertex ) {
        var clip = (( a.z < MIN_Z ) ? 1 : 0) + (( b.z < MIN_Z ) ? 2 : 0) + (( c.z < MIN_Z ) ? 4 : 0);
        if (clip == 7) {
        // All verts are behind the near plane; don't draw.
            return;
        }

        if( clip != 0 ){
            var ab: Vertex;
            var bc: Vertex;
            var ca: Vertex;
            switch (clip) {
                case 1:
                    ab = clip_line( a, b );
                    ca = clip_line( a, c );
                    unclipped( ab, b, c );
                    unclipped( ab, c, ca );
                case 2:
                    ab = clip_line( b, a );
                    bc = clip_line( b, c );
                    unclipped( a, ab, bc );
                    unclipped( a, bc, c );
                case 3:
                    bc = clip_line( b, c );
                    ca = clip_line( a, c );
                    unclipped( c, ca, bc );
                case 4:
                    bc = clip_line( c, b );
                    ca = clip_line( c, a );
                    unclipped( a, b, bc );
                    unclipped( a, bc, ca );
                case 5:
                    ab = clip_line( a, b );
                    bc = clip_line( c, b );
                    unclipped( b, bc, ab );
                case 6:
                    ab = clip_line( a, b );
                    ca = clip_line( a, c );
                    unclipped( a, ab, ca );
            }
            return;
        }
        // No verts need clipping.
        unclipped( a, b, c );
    }
    // Draw a perspective-corrected textured triangle, subdividing as
    // necessary for clipping and texture mapping.
    //
    // Unconventional clipping -- recursively subdivide, and drop whole tris on
    // the wrong side of z clip plane.
    public
    function draw( a: Vertex, b: Vertex, c: Vertex, ?depth_count: Int ){
        var clip = (( a.z < MIN_Z ) ? 1 : 0) + (( b.z < MIN_Z ) ? 2 : 0) + (( c.z < MIN_Z ) ? 4 : 0);
        if( clip == 0 ){
            // No verts need clipping.
            unclipped( a, b, c, depth_count );
            return;
        }
        if( clip == 7 ){
            // All verts are behind the near plane; don't draw.
            return;
        }
        var min_z2 = MIN_Z * 1.1;
        var clip2 = (( a.z < min_z2 ) ? 1 : 0) + (( b.z < min_z2 ) ? 2 : 0) + (( c.z < min_z2 ) ? 4 : 0);
        if (clip2 == 7) {
            // All verts are behind the guard band, don't recurse.
            return;
        }
        var ab = bisect( a, b );
        var bc = bisect( b, c );
        var ca = bisect( c, a );
        var truthy = !( depth_count == 0 && depth_count == null );
        if( truthy ) depth_count--;
        
        if( true ){//xxxxxx  // if( 1 ) ??
            draw( a,  ab, ca, depth_count);
            draw( ab,  b, bc, depth_count);
            draw( bc,  c, ca, depth_count);
            draw( ab, bc, ca, depth_count);
            return;
         }
         
        switch( clip ){
            case 1:
                draw( ab, b, c );
                draw( ab, c, ca );
                draw( a, ab, ca );
            case 2:
                draw( a, ab, bc );
                draw( a, bc, c  );
                draw( b, bc, ab );
            case 3:
                draw( c, ca, bc );
                draw( a, b,  bc );
                draw( a, bc, ca );
            case 4:
                draw( a,  b, bc );
                draw( a, bc, ca );
                draw( bc, c, ca );
            case 5:
                draw( b, bc, ab );
                draw( a, ab, bc );
                draw( a, bc, c  );
            case 6:
                draw( a, ab, ca );
                draw( ab, b, c  );
                draw( ab, c, ca );
        }
    }
}