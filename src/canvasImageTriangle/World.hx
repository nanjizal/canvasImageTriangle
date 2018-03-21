package canvasImageTriangle;
import canvasImageTriangle.AffineMatrix;
import canvasImageTriangle.Point3D;

using canvasImageTriangle.AffineMatrix;
using canvasImageTriangle.Point3D;
class World {
    var mouseGrab    = null;
    var dl                  = null;
    var temp_mat0           = null;
    var temp_mat1           = null;
    var temp_mat2           = null;
    var object              = null;
    var camera              = null;
    var proj                = null;
    var hFov                = ( Math.PI / 2 );
    var lastTime            = 0;
    var omega:              Point3D;
    var distance            = 2.;
    var dt                  = 0;
    public var bigger     = false;
    public var smaller    = false;
    public
    function new( width: Float, height: Float ){
        omega = new Point3D( 2.6, 2.6, 0 );
        temp_mat0   = AffineMatrix.makeIdentityAffine();
        temp_mat1   = AffineMatrix.makeIdentityAffine();
        temp_mat2   = AffineMatrix.makeIdentityAffine();
        proj    = AffineMatrix.makeWindowProjection( width, height, hFov );
        object  = AffineMatrix.makeOrientationAffine( new Point3D( 0.,0.,0. )
                                                   ,  new Point3D( 1.,0.,0. )
                                                   ,  new Point3D( 0.,1.,0. ) );
        camera  = AffineMatrix.makeOrientationAffine( new Point3D( 0.,0., 0.2 + distance )
                                                   ,  new Point3D( 0.,0.,-1.)
                                                   ,  new Point3D( 0.,1., 0.) );
    }
    public inline // used on all Vertex
    function transformVertex( v: Vertex ){
        var p = new Point3D( v.x, v.y, v.z );
        p = AffineMatrix.transformPoint( temp_mat1, p );
        return { x: p.x, y: p.y, z: p.z, u: v.u, v: v.v } 
    }
    public inline
    function spin( x: Float, y: Float, mouseDown: Bool ){
        updateTime();
        updateZoom();
        if( mouseDown ){
            var grabPoint = screenToSpherePt( x, y );
            if( mouseGrab == null && grabPoint != null ) setToGrab( grabPoint );
            if( mouseGrab != null && grabPoint != null ) rotateToGrab( grabPoint );
        } else {
            nullGrab();
        }
    }
    public inline // update of matrices before drawing
    function updateMatrix(){
        var view_mat = camera.makeViewFromOrientation();
        // Update transform.
        AffineMatrix.multiplyAffineTo( proj, view_mat, temp_mat0 );
        AffineMatrix.multiplyAffineTo( temp_mat0, object, temp_mat1 );
    }
    inline
    function rotateObject( scaled: Point3D ) {
        var angle = Math.asin( Math.sqrt( scaled.dotProduct( scaled )));
        if (angle > Math.PI / 8) angle = Math.PI / 8;
        var axis    = scaled.vectorNormalize();
        var mat     = axis.makeRotateAxisAngle( angle );
        object  = mat.multiplyAffine( object );
        object.orthonormalizeRotation();
    }
    inline
    function nullGrab(){
        mouseGrab = null;
        omega = omega.vectorScale( 0.95 );
        var dotOmegaProduct = omega.dotProduct( omega );
        if( dotOmegaProduct < 0.000000001 && bigger == false && smaller == false) {
            omega = new Point3D( 0, 0, 0 );
            // renderOn = false
        } else {
            rotateObject( omega.vectorScale( dt / 1000 ) );
        }
    }
    inline
    function setToGrab( newGrab: Point3D ){
        mouseGrab = object.applyInverseRotation( newGrab );
    }
    inline
    function rotateToGrab( newGrab: Point3D ){
        var origGrab = object.applyRotation( mouseGrab );
        // Rotate the object, to map old grab point onto new grab point.
        var axis = origGrab.crossProduct( newGrab );
        axis = axis.vectorScale( 0.95 );
        rotateObject( axis );
        omega = axis.vectorScale( 1000 / dt );
    }
    inline
    function updateZoom(){
        if( bigger )     distance -= 2.0 * dt / 1000;
        if( smaller )    distance += 2.0 * dt / 1000;
        if( distance < 0 ) distance = 0.;
        camera.e14 = 0.2 + distance;
    }
    inline
    function updateTime(){
        var now = Std.int( Date.now().getTime() );
        dt = now - lastTime;
        lastTime = now;
        if( dt > 100 ) dt = 100;
        if( dt < 1 )   dt = 1;
    }
    inline
    function screenToSpherePt( x: Float, y: Float ): Point3D {
        var p         = new Point3D( camera.e12, camera.e13, camera.e14 + 1. );
        var r         = new Point3D( camera.e0,  camera.e1,  camera.e2  );// camera dir
        var up        = new Point3D( camera.e4,  camera.e5,  camera.e6  );
        var right     = new Point3D( camera.e8,  camera.e9,  camera.e10 );
        var tan_half  = Math.tan( hFov / 2 );
        r = r.vectorAdd( right.vectorScale( x * tan_half ) );
        r = r.vectorAdd(    up.vectorScale( y * tan_half ) );
        r = r.vectorNormalize();
        return rayVsUnitSphereClosestPoint( p, r );
    }
    // Return the first exterior hit or closest point between the unit
    // sphere and the ray starting at p and going in the r direction.
    inline static
    function rayVsUnitSphereClosestPoint( p: Point3D, r: Point3D ): Point3D {
        if( p.dotProduct( p ) < 1 ) return null;// Ray is inside sphere, no exterior hit.
        var ray = - p.dotProduct( r ); // along ray
        if( ray < 0 ) return null;// Behind ray start-point.
        var perp = p.vectorAdd( r.vectorScale( ray ) );
        if( perp.dotProduct( perp ) >= 0.999999 ) return perp.vectorNormalize();// Return the closest point.
        // Compute intersection.
        var e = Math.sqrt( 1 - perp.dotProduct( perp ) );
        var hit = p.vectorAdd( r.vectorScale( ray - e ) );
        return hit.vectorNormalize();
    }
}