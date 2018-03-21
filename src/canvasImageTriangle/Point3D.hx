package canvasImageTriangle;

typedef P3D = { x: Float, y: Float, z: Float };
@:forward
abstract Point3D( P3D ) from P3D to P3D {
    
    public inline 
    function new( x_: Float, y_: Float, z_: Float ){
        this = { x: x_, y: y_, z: z_ };
    }
    
    public static inline
    function projectPoint( p: Point3D ): Point3D {
        return if( p.z <= 0 ) {
            new Point3D( 0., 0., p.z );
        } else {
            new Point3D( p.x / p.z, p.y / p.z, p.z );
        }
    }
    
    public static inline
    function projectPointTo( p: Point3D, out: Point3D ) {
        out.z = p.z;
        if (p.z <= 0) {
            out.x = 0;
            out.y = 0;
        } else {
            out.x = p.x / p.z;
            out.y = p.y / p.z;
        }
    }
    public static inline
    function vectorDupe( a: Point3D ): Point3D {
        return new Point3D( a.x, a.y, a.z );
    }
    public static inline
    function vectorCopyTo( a: Point3D, b: Point3D ) {
        b.x = a.x;
        b.y = a.y;
        b.z = a.z;
    }
    public static inline
    function crossProduct( a: Point3D, b: Point3D ): Point3D {
        // a1b2 - a2b1, a2b0 - a0b2, a0b1 - a1b0
        return new Point3D( a.y * b.z - a.z * b.y
                        , a.z * b.x - a.x * b.z
                        , a.x * b.y - a.y * b.x );
    }
    public static inline
    function dotProduct( a: Point3D, b: Point3D ): Float {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    public static inline
    function vectorAdd( a: Point3D, b: Point3D ): Point3D {
      return new Point3D( a.x + b.x, a.y + b.y, a.z + b.z );
    }
    public static inline
    function vectorSub( a: Point3D, b: Point3D ): Point3D {
        return new Point3D( a.x - b.x, a.y - b.y, a.z - b.z );
    }
    public static inline
    function vectorScale( v: Point3D, s: Float ): Point3D {
        return new Point3D( v.x * s, v.y * s, v.z * s );
    }
    public static inline
    function vectorNormalize( v: Point3D ): Point3D {
      var l2 = dotProduct( v, v );
      return if( l2 <= 0 ){
            // Punt.
                new Point3D( 1., 0., 0. );
            } else {
                var scale = 1 / Math.sqrt(l2);
                new Point3D( v.x * scale, v.y * scale, v.z * scale );
            }
    }
    public static inline 
    function vectorLength( v: Point3D ): Float {
        var l2 = dotProduct( v, v );
        return Math.sqrt( l2 );
    }
    public static inline
    function vectorDistance( a: Point3D, b: Point3D ):Float {
        var dx = ( a.x - b.x );
        var dy = ( a.y - b.y );
        var dz = ( a.z - b.z );
        var l2 =  dx * dx + dy * dy + dz * dz;
        return Math.sqrt( l2 );
    }
    
}