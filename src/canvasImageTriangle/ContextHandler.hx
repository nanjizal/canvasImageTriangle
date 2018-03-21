package canvasImageTriangle;
import canvasImageTriangle.CanvasRenderingContext25D;
import canvasImageTriangle.AffineMatrix;
import canvasImageTriangle.Vertex;
import js.html.Image;
// Does not appear to be needed for this demo
class ContextHandler {
    var context: CanvasRenderingContext25D;
    public var transform: AffineMatrix;
    var texture:   Image;
    var tempverts:  Array<Vertex>;
    var tempVert0: Vertex;
    public
    function new( ctx_: CanvasRenderingContext25D ){
        context = ctx_;
        transform = new AffineMatrix();
        texture = null;
        tempverts = [];
        tempVert0 = { x: 0, y: 0, z: 0, u: 0, v: 0 };
    }
    public
    function setTransform( mat: AffineMatrix ) {
          AffineMatrix.copyAffineMatrix( transform, mat );
    }
    public
    function setTexture( tex: Image ) {
      texture = tex;
    }
    public 
    function expandVertexs( size: Int ) {
      var temps = this.tempverts;
      var expand = size - temps.length;
      for( i in 0...expand ) temps[ i ] = { x: 0, y: 0, z: 0, u: 0, v: 0 };
    }
    public 
    function drawTris( verts: Array<Vertex>, trilist: Array<Int> ) {
        expandVertexs( verts.length );
        var temps   = tempverts;
        var tx      = transform;
        var tempv0  = tempVert0;
        var n       = verts.length;
        for( i in 0...n ) {
            AffineMatrix.transformPointTo( tx, verts[ i ], tempv0 );
            Point3D.projectPointTo( tempv0, temps[ i ] );
            temps[ i ].u = verts[ i ].u;
            temps[ i ].v = verts[ i ].v;
        }
        var ctx = context;
        var tex = texture;
        var a: Vertex;
        var b: Vertex;
        var c: Vertex;
        n = trilist.length - 2;
        var i = 0;
        while( i < n ) {
            a = temps[ trilist[ i ] ];
            b = temps[ trilist[ i + 1 ] ];
            c = temps[ trilist[ i + 2 ] ];
            if( a.z <= 0 || b.z <= 0 && c.z <= 0 ) {
                // Crosses zero plane; cull it.
                // TODO: clip?
                i += 3;
                continue;
            }
            if( signedArea( a, b, c ) ) {
                // Backfacing.
                i += 3;
                continue;
            }
            context.drawTriangle(   tex,
                                a.x, a.y, b.x, b.y, c.x, c.y,
                                a.u, a.v, b.u, b.v, c.u, c.v);
            i += 3;
        }
    }
    public static inline 
        function signedArea( a: Vertex, b: Vertex, c: Vertex ): Bool {
        return ( b.x - a.x ) * ( c.y - a.y ) - ( b.y - a.y ) * ( c.x - a.x ) > 0;
    }
}