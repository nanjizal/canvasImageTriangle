package;
// By Thatcher Ulrich http://tulrich.com 2009
//
// This source code has been donated to the Public Domain.  Do
// whatever you want with it.  Use at your own risk.
// 
// http://tulrich.com/geekstuff/canvas/perspective.html
// 
// converted to Haxe by Nanjizal on 20 March 2018
// 


import js.Browser;
import js.html.Element;
import js.html.ImageElement;
import js.html.CanvasRenderingContext2D;
import htmlHelper.canvas.CanvasWrapper;
import htmlHelper.tools.ImageLoader;
import htmlHelper.tools.AnimateTimer;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.MouseEvent;
import js.html.Element;

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

class Main  {
    var surface:            CanvasRenderingContext25D;
    public static var canvas: CanvasWrapper;
    var contextHandler:     ContextHandler;
    var loader:             ImageLoader;
    var image:              ImageElement;
    var picture:            String = 'nyt_nov5.jpg';
    var dl                  = null;
    var canvas_elem         = null;
    var c3d                 = null;
    var temp_mat0           = null;
    var temp_mat1           = null;
    var temp_mat2           = null;
    var object_mat          = null;
    var camera_mat          = null;
    var proj_mat            = null;
    var timer_id            = null;
    var options:            Options;
    var mouse_x             = 0.;
    var mouse_y             = 0.;
    var mouse_grab_point    = null;
    var mouse_is_down       = false;
    var horizontal_fov_radians = Math.PI / 2;
    var object_omega:       Point3D;
    var target_distance     = 2.;
    var zoom_in_pressed     = false;
    var zoom_out_pressed    = false;
    var last_spin_time      = 0.;
    var draw_wireframe      = false;
    var MIN_Z               = 0.05;
    var width               = 1024.;
    var height              = 768.;
    static function main( ){
        canvas = new CanvasWrapper();
        canvas.width = 1024;
        canvas.height = 768;
        Browser.document.body.appendChild( cast canvas );
        new Main( new CanvasRenderingContext25D( canvas.getContext2d() ) );
    }
    public 
    function new( surface_: CanvasRenderingContext25D ){
        surface = surface_;
        object_omega = new Point3D( 2.6, 2.6, 0 );
        options  = {  draw_backfaces: true, whiteout_alpha: 1
                 ,    wireframe: false, subdivide_factor: 10.0
                 ,    nonadaptive_depth: 0 };
        temp_mat0   = AffineMatrix.makeIdentityAffine();
        temp_mat1   = AffineMatrix.makeIdentityAffine();
        temp_mat2   = AffineMatrix.makeIdentityAffine();
        proj_mat    = AffineMatrix.makeWindowProjection( width, height, horizontal_fov_radians );
        object_mat  = AffineMatrix.makeOrientationAffine( new Point3D( 0.,0.,0. )
                                                       ,  new Point3D( 1.,0.,0. )
                                                       ,  new Point3D( 0.,1.,0. ) );
        camera_mat  = AffineMatrix.makeOrientationAffine( new Point3D( 0.,0., 0.2 + target_distance )
                                                       ,  new Point3D( 0.,0.,-1.)
                                                       ,  new Point3D( 0.,1., 0.) );
        contextHandler = new ContextHandler( surface );
        loader = new ImageLoader( [ picture ], onLoaded );
    }
    function onLoaded(){ //trace( 'loaded assests');
        var images: Hash<ImageElement>  = loader.images;
        image                           = images.get( picture );
        animate();
        Browser.document.onkeydown = keyDown;
        Browser.document.onkeyup   = keyUp;
        Browser.document.onmousemove = mousemove;
        Browser.document.onmousedown = mousedown;
        Browser.document.onmouseup = mouseup;
    }
    function animate(){
        AnimateTimer.onFrame = render;
        AnimateTimer.create();
    }
    inline 
    function render( count: Int ){
        //surface.clearRect( 0, 0, 1024, 768 );
        if( allowSpin ) spin();
    }
    // do I need this?
    function getTime() {
      return Date.now().getTime();
    }
    // Return the point between two points, also bisect the texture coords.
    function bisect( p: Vertex, q: Vertex ): Vertex {
        var p = {   x: ( p.x + q.x ) / 2,
                    y: ( p.y + q.y ) / 2,
                    z: ( p.z + q.z ) / 2,
                    u: ( p.u + q.u ) / 2,
                    v: ( p.v + q.v ) / 2 };
        return p;
    }
    
    // for debugging
    function drawPerspectiveTriUnclippedSubX( a: Vertex, tv0: Point3D
                                            , b: Vertex, tv1: Point3D
                                            , c: Vertex, tv2: Point3D ) {
        surface.beginPath();
        surface.moveTo( tv0.x, tv0.y );
        surface.lineTo( tv1.x, tv1.y );
        surface.lineTo( tv2.x, tv2.y );
        surface.lineTo( tv0.x, tv0.y );
        surface.stroke();
    }
    function drawPerspectiveTriUnclippedSub( a: Vertex, tv0: Point3D
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

        if( depth_count != null ){
            depth_count--;
            if( depth_count == null ){
                subdiv = 0;
            } else {
                subdiv = 7;
            }
        }

        if (subdiv == 0) {
            if (draw_wireframe) {
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
                drawPerspectiveTriUnclippedSub( a, tv0, v01, tv01, c, tv2);
                drawPerspectiveTriUnclippedSub( v01, tv01, b, tv1, c, tv2);
            case 2:
                // split along v0-v12
                drawPerspectiveTriUnclippedSub( a, tv0, b, tv1, v12, tv12);
                drawPerspectiveTriUnclippedSub( a, tv0, v12, tv12, c, tv2);
            case 3:
                // split along v01-v12
                drawPerspectiveTriUnclippedSub( a, tv0, v01, tv01, v12, tv12);
                drawPerspectiveTriUnclippedSub( a, tv0, v12, tv12, c, tv2);
                drawPerspectiveTriUnclippedSub( v01, tv01, b, tv1, v12, tv12);
            case 4:
                // split along v1-v20
                drawPerspectiveTriUnclippedSub( a, tv0, b, tv1, v20, tv20 );
                drawPerspectiveTriUnclippedSub( b, tv1, c, tv2, v20, tv20 );
            case 5:
                // split along v01-v20
                drawPerspectiveTriUnclippedSub( a, tv0, v01, tv01, v20, tv20);
                drawPerspectiveTriUnclippedSub( b, tv1, c, tv2, v01, tv01);
                drawPerspectiveTriUnclippedSub( c, tv2, v20, tv20, v01, tv01);
            case 6:
                // split along v12-v20
                drawPerspectiveTriUnclippedSub( a, tv0, b, tv1, v20, tv20);
                drawPerspectiveTriUnclippedSub( b, tv1, v12, tv12, v20, tv20);
                drawPerspectiveTriUnclippedSub( v12, tv12, c, tv2, v20, tv20);
            default: // 7
                drawPerspectiveTriUnclippedSub( a, tv0, v01, tv01, v20, tv20, depth_count);
                drawPerspectiveTriUnclippedSub( b, tv1, v12, tv12, v01, tv01, depth_count);
                drawPerspectiveTriUnclippedSub( c, tv2, v20, tv20, v12, tv12, depth_count);
                drawPerspectiveTriUnclippedSub( v01, tv01, v12, tv12, v20, tv20, depth_count);
        }
        return;
    }
    function drawPerspectiveTriUnclipped( a: Vertex, b: Vertex, c: Vertex, ?depth_count: Int) {
        var tv0 = Point3D.projectPoint( a );
        var tv1 = Point3D.projectPoint( b );
        var tv2 = Point3D.projectPoint( c );
        drawPerspectiveTriUnclippedSub( a, tv0, b, tv1, c, tv2, depth_count );
    }
    // Given an edge that crosses the z==MIN_Z plane, return the
    // intersection of the edge with z==MIN_Z.
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
    function drawPerspectiveTriConventionalClipping( a: Vertex, b: Vertex, c: Vertex ) {
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
                    drawPerspectiveTriUnclipped( ab, b, c );
                    drawPerspectiveTriUnclipped( ab, c, ca );
                case 2:
                    ab = clip_line( b, a );
                    bc = clip_line( b, c );
                    drawPerspectiveTriUnclipped( a, ab, bc );
                    drawPerspectiveTriUnclipped( a, bc, c );
                case 3:
                    bc = clip_line( b, c );
                    ca = clip_line( a, c );
                    drawPerspectiveTriUnclipped( c, ca, bc );
                case 4:
                    bc = clip_line( c, b );
                    ca = clip_line( c, a );
                    drawPerspectiveTriUnclipped( a, b, bc );
                    drawPerspectiveTriUnclipped( a, bc, ca );
                case 5:
                    ab = clip_line( a, b );
                    bc = clip_line( c, b );
                    drawPerspectiveTriUnclipped( b, bc, ab );
                case 6:
                    ab = clip_line( a, b );
                    ca = clip_line( a, c );
                    drawPerspectiveTriUnclipped( a, ab, ca );
            }
            return;
        }
        // No verts need clipping.
        drawPerspectiveTriUnclipped( a, b, c );
    }
    // Draw a perspective-corrected textured triangle, subdividing as
    // necessary for clipping and texture mapping.
    //
    // Unconventional clipping -- recursively subdivide, and drop whole tris on
    // the wrong side of z clip plane.
    function drawPerspectiveTri( a: Vertex, b: Vertex, c: Vertex, ?depth_count: Int ){
        var clip = (( a.z < MIN_Z ) ? 1 : 0) + (( b.z < MIN_Z ) ? 2 : 0) + (( c.z < MIN_Z ) ? 4 : 0);
        if( clip == 0 ){
            // No verts need clipping.
            drawPerspectiveTriUnclipped( a, b, c, depth_count );
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
        if( depth_count != -1 ) depth_count--;
        
        if( true ){//xxxxxx  // if( 1 ) ??
            drawPerspectiveTri( a,  ab, ca, depth_count);
            drawPerspectiveTri( ab,  b, bc, depth_count);
            drawPerspectiveTri( bc,  c, ca, depth_count);
            drawPerspectiveTri( ab, bc, ca, depth_count);
            return;
         }
         
        switch( clip ){
            case 1:
                drawPerspectiveTri( ab, b, c );
                drawPerspectiveTri( ab, c, ca );
                drawPerspectiveTri( a, ab, ca );
            case 2:
                drawPerspectiveTri( a, ab, bc );
                drawPerspectiveTri( a, bc, c  );
                drawPerspectiveTri( b, bc, ab );
            case 3:
                drawPerspectiveTri( c, ca, bc );
                drawPerspectiveTri( a, b,  bc );
                drawPerspectiveTri( a, bc, ca );
            case 4:
                drawPerspectiveTri( a,  b, bc );
                drawPerspectiveTri( a, bc, ca );
                drawPerspectiveTri( bc, c, ca );
            case 5:
                drawPerspectiveTri( b, bc, ab );
                drawPerspectiveTri( a, ab, bc );
                drawPerspectiveTri( a, bc, c  );
            case 6:
                drawPerspectiveTri( a, ab, ca );
                drawPerspectiveTri( ab, b, c  );
                drawPerspectiveTri( ab, c, ca );
        }
    }
    function draw(){
        // Clear with white.
        surface.globalAlpha = options.whiteout_alpha;
        surface.fillStyle = '#FFFFFF';
        surface.fillRect( 0, 0, width, height );
        surface.globalAlpha = 1;

        var view_mat = AffineMatrix.makeViewFromOrientation( camera_mat );

        // Update transform.
        AffineMatrix.multiplyAffineTo( proj_mat, view_mat, temp_mat0 );
        AffineMatrix.multiplyAffineTo( temp_mat0, object_mat, temp_mat1 );
        contextHandler.setTransform( temp_mat1 );

        // Draw.
        var im_width = image.width;
        var im_height = image.height;
        var verts:Array<Vertex> = [ { x:-1, y:-1, z: 0, u:0, v:0 },
                                    { x: 1, y:-1, z: 0, u:im_width, v:0 },
                                    { x: 1, y: 1, z: 0, u:im_width, v:im_height },
                                    { x:-1, y: 1, z: 0, u:0, v:im_height } ];
        var tverts: Array<Vertex> = [];
        for( i in 0...verts.length ){
            var v: Vertex = verts[ i ];
            var p: Point3D = new Point3D( v.x, v.y, v.z );
            p = AffineMatrix.transformPoint( contextHandler.transform, p );
            tverts.push( 
                { x: p.x, y: p.y, z: p.z, u: verts[ i ].u, v: verts[ i ].v } 
                );
            //tverts[ i ].u = verts[ i ].u;
            //tverts[ i ].v = verts[ i ].v;
        }
        var depth = options.nonadaptive_depth;
        drawPerspectiveTri( tverts[ 0 ], tverts[ 1 ], tverts[ 2 ], depth );
        drawPerspectiveTri( tverts[ 0 ], tverts[ 2 ], tverts[ 3 ], depth );
        if( options.wireframe ){
            surface.globalAlpha = 0.3;
            surface.fillRect( 0, 0, width, height );
            draw_wireframe = true;
            surface.globalAlpha = 1;
            drawPerspectiveTri( tverts[ 0 ], tverts[ 1 ], tverts[ 2 ], depth );
            drawPerspectiveTri( tverts[ 0 ], tverts[ 2 ], tverts[ 3 ], depth );
            draw_wireframe = false;
        }
    }
    function rotateObject( scaled_axis: Point3D ) {
        var angle = Math.asin( Math.sqrt( Point3D.dotProduct( scaled_axis, scaled_axis )));
        if (angle > Math.PI / 8) angle = Math.PI / 8;
        var axis    = Point3D.vectorNormalize( scaled_axis );
        var mat     = AffineMatrix.makeRotateAxisAngle( axis, angle );
        object_mat  = AffineMatrix.multiplyAffine( mat, object_mat );
        AffineMatrix.orthonormalizeRotation( object_mat );
    }
    
    function spin() {
        var t_now = getTime();
        var dt = t_now - last_spin_time;
        last_spin_time = t_now;
        if( dt > 100 ) dt = 100;
        if( dt < 1 )   dt = 1;
        // Zoom.
        if( zoom_in_pressed )     target_distance -= 2.0 * dt / 1000;
        if( zoom_out_pressed )    target_distance += 2.0 * dt / 1000;
        if( target_distance < 0 ) target_distance = 0.;
        camera_mat.e14 = 0.2 + target_distance;
        if( mouse_is_down ){
            var new_grab_point = screenToSpherePt( mouse_x, mouse_y );
            if( mouse_grab_point == null && new_grab_point != null ) {
                mouse_grab_point = AffineMatrix.applyInverseRotation( object_mat, new_grab_point );
            }
            if( mouse_grab_point != null && new_grab_point != null ){
                var orig_grab_point = AffineMatrix.applyRotation( object_mat, mouse_grab_point );
                // Rotate the object, to map old grab point onto new grab point.
                var axis = Point3D.crossProduct( orig_grab_point, new_grab_point );
                axis = Point3D.vectorScale( axis, 0.95 );
                rotateObject( axis );
                object_omega = Point3D.vectorScale( axis, 1000 / dt );
            }
        } else {
            mouse_grab_point = null;
            object_omega = Point3D.vectorScale( object_omega, 0.95 );
            if( Point3D.dotProduct( object_omega, object_omega ) < 0.000000001 &&
                                                                    zoom_in_pressed == false &&
                                                                    zoom_out_pressed == false) {
                object_omega = new Point3D( 0, 0, 0 );
                stop_spinning();
                draw();
                return;
            }
            var axis = Point3D.vectorScale( object_omega, dt / 1000 );
            rotateObject( axis );
        }
        draw();
    }
    // Return the first exterior hit or closest point between the unit
    // sphere and the ray starting at p and going in the r direction.
    function rayVsUnitSphereClosestPoint( p: Point3D, r: Point3D ): Point3D {
        var p_len2 = Point3D.dotProduct( p, p );
        if( p_len2 < 1 ) {
            // Ray is inside sphere, no exterior hit.
            return null;
        }
        var along_ray = -Point3D.dotProduct( p, r );
        if( along_ray < 0 ){
            // Behind ray start-point.
            return null;
        }
        var perp = Point3D.vectorAdd( p, Point3D.vectorScale( r, along_ray ) );
        var perp_len2 = Point3D.dotProduct( perp, perp );
        if (perp_len2 >= 0.999999) {
            // Return the closest point.
            return Point3D.vectorNormalize( perp );
        }
        // Compute intersection.
        var e = Math.sqrt( 1 - Point3D.dotProduct( perp, perp ) );
        var hit = Point3D.vectorAdd( p, Point3D.vectorScale( r, ( along_ray - e ) ) );
        return Point3D.vectorNormalize( hit );
    }
    function screenToSpherePt( x: Float, y: Float ): Point3D {
      var p         = new Point3D( camera_mat.e12, camera_mat.e13, camera_mat.e14 + 1 );
      // camera dir
      var r         = new Point3D( camera_mat.e0, camera_mat.e1, camera_mat.e2  );
      var up        = new Point3D( camera_mat.e4, camera_mat.e5, camera_mat.e6  );
      var right     = new Point3D( camera_mat.e8, camera_mat.e9, camera_mat.e10 );
      var tan_half  = Math.tan( horizontal_fov_radians / 2 );
      r = Point3D.vectorAdd( r, Point3D.vectorScale( right, x * tan_half ) );
      r = Point3D.vectorAdd( r, Point3D.vectorScale( up, y * tan_half ) );
      r = Point3D.vectorNormalize( r );
      return rayVsUnitSphereClosestPoint( p, r );
    }
    function rememberMousePos( e ){
        var width_  = width;
        var height_ = height;
        var element:Element = cast( canvas, Element );
        mouse_x = (( e.clientX - element.offsetLeft ) / width_ ) * 2 - 1;
        mouse_y = -((( e.clientY - element.offsetTop ) - height_ / 2 ) / ( width_ / 2 ));
    }
    function mousedown( e ){
        mouse_is_down = true;
        rememberMousePos( e );
        start_spinning();
    }
    function mouseup( e ) {
      mouse_is_down = false;
    }
    //var mev;
    function mousemove( e ){
        //var mev = e;
        rememberMousePos( e );
        if( mouse_is_down ) start_spinning();
    }
    function keyDown( e: KeyboardEvent ){
        e.preventDefault();
        var keyCode = e.keyCode;
        switch( keyCode ){
            case KeyboardEvent.DOM_VK_A:
                zoom_in_pressed = true;
                start_spinning();
            case KeyboardEvent.DOM_VK_Z:
                zoom_out_pressed = true;
                start_spinning();
            case KeyboardEvent.DOM_VK_W:
                options.wireframe = !options.wireframe;
                start_spinning();
            default:
            
        }
    }
    function keyUp( e: KeyboardEvent ){
        e.preventDefault();
        var keyCode = e.keyCode;
        switch( keyCode ){
            case KeyboardEvent.DOM_VK_A:
                zoom_in_pressed = false;
            case KeyboardEvent.DOM_VK_Z:
                zoom_out_pressed = false;
            default:
                
        }
    }
    var allowSpin = false;
    function start_spinning() {
        //if( timer_id == null ) timer_id = setInterval( spin, 15 );
        allowSpin = true; 
    }
    function stop_spinning() {
        allowSpin = false;
        /*
        if( timer_id != null ){
            clearInterval( timer_id );
            timer_id = null;
        }*/
    }
    
}