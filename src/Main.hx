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
//import canvasImageTriangle.ContextHandler;
import canvasImageTriangle.Point;
import canvasImageTriangle.Point3D;
import canvasImageTriangle.Vertex;
import canvasImageTriangle.PerspectiveTri;
import canvasImageTriangle.World;

class Main  {
    var surface:            CanvasRenderingContext25D;
    var canvas:             CanvasWrapper;
    var element:            Element;
    var world:              World;
    var perspectiveTri:     PerspectiveTri;
    var loader:             ImageLoader;
    var image:              ImageElement;
    var options:            Options;
    var picture:            String = 'nyt_nov5.jpg';
    var renderOn            = true;
    var x                   = 0.;
    var y                   = 0.;
    var down                = false;
    var width               = 1024.;
    var height              = 768.;
    var left                : Float;
    var top                 : Float;
    static function main( ){ new Main(); } public function new(){
        canvas          = new CanvasWrapper();
        element         = cast( canvas, Element );
        canvas.width    = Std.int( width );
        canvas.height   = Std.int( height );
        left            = element.offsetLeft;
        top             = element.offsetTop;
        Browser.document.body.appendChild( cast canvas );
        surface = new CanvasRenderingContext25D( canvas.getContext2d() );
        world   = new World( width, height );
        loader  = new ImageLoader( [ picture ], onLoaded );
    }
    public
    function onLoaded(){ 
        trace( 'loaded image' );
        image                        = loader.images.get( picture );
        options                      = initOpitions();
        perspectiveTri               = new PerspectiveTri( surface, image, options );
        world.spin( x, y, down );
        perspectiveTri.render( vertices(), width, height );
        world.updateMatrix();
        renderOn            = true;
        animate();
        Browser.document.onkeydown   = keyDown;
        Browser.document.onkeyup     = keyUp;
        Browser.document.onmousemove = mousemove;
        Browser.document.onmousedown = mousedown;
        Browser.document.onmouseup   = mouseup;
    }
    inline
    function initOpitions(): Options {
        return {    draw_backfaces:     true
                ,   whiteout_alpha:     1
                ,   wireframe:          false
                ,   subdivide_factor:   10.0
                ,   nonadaptive_depth:  0 
            };
    }
    function animate(){
        AnimateTimer.onFrame = render;
        AnimateTimer.create();
    }
    inline 
    function render( count: Int ){
        if( renderOn ) {
            world.spin( x, y, down );
            perspectiveTri.render( vertices(), width, height );
            world.updateMatrix();
            if( !down ) renderOn = false;
        }
    }
    function vertices(): Array<Vertex> {
        var verts  = initVert();
        var tverts = new Array<Vertex>();
        for( i in 0...verts.length ) tverts[ i ] = world.transformVertex( verts[ i ] );
        return tverts;
    }
    inline 
    function initVert():Array<Vertex>{
        var w = width;
        var h = height;
        return
        [ { x:-1., y:-1., z: 0., u:0., v:0. },
          { x: 1., y:-1., z: 0., u:w,  v:0. },
          { x: 1., y: 1., z: 0., u:w,  v:h },
          { x:-1., y: 1., z: 0., u:0., v:h } ];
    }
    function rememberMousePos( e ){
        var w = width;
        var h = height;
        x = (( e.clientX - left ) / w ) * 2 - 1;
        y = -((( e.clientY - top ) - h / 2 ) / ( w / 2 ));
    }
    function mousedown( e ){
        down = true;
        rememberMousePos( e );
        renderOn = true;
    }
    function mouseup( e ) {
        down = false;
    }
    function mousemove( e ){
        rememberMousePos( e );
        if( down ) renderOn = true;
    }
    function keyDown( e: KeyboardEvent ){
        e.preventDefault();
        var keyCode = e.keyCode;
        switch( keyCode ){
            case KeyboardEvent.DOM_VK_A:
                world.bigger = true;
                renderOn = true;
            case KeyboardEvent.DOM_VK_Z:
                world.smaller = true;
                renderOn = true;
            case KeyboardEvent.DOM_VK_W:
                options.wireframe = !options.wireframe;
                renderOn = true;
            default:
                //
        }
    }
    function keyUp( e: KeyboardEvent ){
        e.preventDefault();
        var keyCode = e.keyCode;
        switch( keyCode ){
            case KeyboardEvent.DOM_VK_A:
                world.bigger = false;
            case KeyboardEvent.DOM_VK_Z:
                world.smaller = false;
            default:
                //
        }
    }
}