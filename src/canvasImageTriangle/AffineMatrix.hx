package canvasImageTriangle;
import canvasImageTriangle.Point3D;

class AffineMatrix {
    public var e0: Float   = 1;
    public var e4: Float   = 0;
    public var e8: Float   = 0;
    public var e12: Float  = 0;
    
    public var e1: Float   = 0;
    public var e5: Float   = 1;
    public var e9: Float   = 0;
    public var e13: Float  = 0;
    
    public var e2: Float   = 0;
    public var e6: Float   = 0;
    public var e10: Float  = 1;
    public var e14: Float  = 0;
    
    public function new(){
        
    }

    // ------------------------------------------------------------

    // NOTE(tulrich): the element numbering is based on OpenGL/DX
    // conventions, where memory is laid out like:
    //
    // [ x[0]   x[4]   x[8]   x[12] ]
    // [ x[1]   x[5]   x[9]   x[13] ]
    // [ x[2]   x[6]   x[10]  x[14] ]
    // [ x[3]   x[7]   x[11]  x[15] ]
    //
    // The translate part is in x[12], x[13], x[14].  We don't
    // actually store the bottom row, so elements 3, 7, 11, and 15
    // don't exist!

    // This represents an affine 3x4 matrix.  This was originally just done with
    // object literals, but there is a 10 property limit for map sharing in v8.
    // Since we have 12 properties, and don't generally construct matrices in
    // critical loops, using a constructor function makes sure the map is shared.
    public static inline
    function matrix( e0_: Float, e4_: Float, e8_:  Float, e12_: Float
                  ,  e1_: Float, e5_: Float, e9_:  Float, e13_: Float
                  ,  e2_: Float, e6_: Float, e10_: Float, e14_: Float) {
        var a = new AffineMatrix();
        a.e0  = e0_;
        a.e4  = e4_;
        a.e8  = e8_;
        a.e12 = e12_;
        a.e1  = e1_;
        a.e5  = e5_;
        a.e9  = e9_;
        a.e13 = e13_;
        a.e2  = e2_;
        a.e6  = e6_;
        a.e10 = e10_;
        a.e14 = e14_;
        return a;
    }
    public static inline
    function setAffineMatrix( out: AffineMatrix
                            , e0: Float, e4: Float, e8: Float, e12: Float
                            , e1: Float, e5: Float, e9: Float, e13: Float
                            , e2, e6, e10, e14) {
        out.e0  = e0;
        out.e4  = e4;
        out.e8  = e8;
        out.e12 = e12;
        out.e1  = e1;
        out.e5  = e5;
        out.e9  = e9;
        out.e13 = e13;
        out.e2  = e2;
        out.e6  = e6;
        out.e10 = e10;
        out.e14  = e14;
    }
    public static inline
    function copyAffineMatrix( dest: AffineMatrix, src: AffineMatrix ) {
        dest.e0  = src.e0;
        dest.e4  = src.e4;
        dest.e8  = src.e8;
        dest.e12 = src.e12;
        dest.e1  = src.e1;
        dest.e5  = src.e5;
        dest.e9  = src.e9;
        dest.e13 = src.e13;
        dest.e2  = src.e2;
        dest.e6  = src.e6;
        dest.e10 = src.e10;
        dest.e14 = src.e14;
    }

    // Apply the affine 3x4 matrix transform to point |p|.  |p| should
    // be a 3 element array, and |t| should be a 16 element array...
    // Technically transformations should be a 4x4 matrix for
    // homogeneous coordinates, but we're not currently using the
    // extra abilities so we can keep things cheaper by avoiding the
    // extra row of calculations.
    public static inline
    function transformPoint( t: AffineMatrix, p: Point3D ): Point3D {
        return {
                  x: t.e0 * p.x + t.e4 * p.y + t.e8  * p.z + t.e12,
                  y: t.e1 * p.x + t.e5 * p.y + t.e9  * p.z + t.e13,
                  z: t.e2 * p.x + t.e6 * p.y + t.e10 * p.z + t.e14
              };
    }
    // As above, but puts result in given output object.
    public static inline
    function transformPointTo( t: AffineMatrix, p: Point3D, out: Point3D ) {
        out.x = t.e0 * p.x + t.e4 * p.y + t.e8  * p.z + t.e12;
        out.y = t.e1 * p.x + t.e5 * p.y + t.e9  * p.z + t.e13;
        out.z = t.e2 * p.x + t.e6 * p.y + t.e10 * p.z + t.e14;
    }
    public static inline
    function applyRotation( t: AffineMatrix, p: Point3D ): Point3D {
        return {
            x: t.e0 * p.x + t.e4 * p.y + t.e8  * p.z,
            y: t.e1 * p.x + t.e5 * p.y + t.e9  * p.z,
            z: t.e2 * p.x + t.e6 * p.y + t.e10 * p.z
        };
    }
    public static inline
    function applyInverseRotation( t: AffineMatrix, p: Point3D ): Point3D {
        return {
            x: t.e0 * p.x + t.e1 * p.y + t.e2  * p.z,
            y: t.e4 * p.x + t.e5 * p.y + t.e6  * p.z,
            z: t.e8 * p.x + t.e9 * p.y + t.e10 * p.z
        };
    }
    // This is an unrolled matrix multiplication of a x b.  It is really a 4x4
    // multiplication, but with 3x4 matrix inputs and a 3x4 matrix output.  The
    // last row is implied to be [0, 0, 0, 1].
    public static inline
    function multiplyAffine( a: AffineMatrix, b: AffineMatrix ): AffineMatrix {
      // Avoid repeated property lookups by making access into the local frame.
      var a0 = a.e0;
      var a1 = a.e1; 
      var a2 = a.e2;
      var a4 = a.e4;
      var a5 = a.e5; 
      var a6 = a.e6;
      var a8 = a.e8;
      var a9 = a.e9; 
      var a10 = a.e10;
      var a12 = a.e12;
      var a13 = a.e13;
      var a14 = a.e14;
      var b0 = b.e0;
      var b1 = b.e1;
      var b2 = b.e2; 
      var b4 = b.e4;
      var b5 = b.e5;
      var b6 = b.e6;
      var b8 = b.e8;
      var b9 = b.e9;
      var b10 = b.e10;
      var b12 = b.e12; 
      var b13 = b.e13;
      var b14 = b.e14;

      return AffineMatrix.matrix(
                                  a0 * b0  + a4 * b1  + a8 * b2,
                                  a0 * b4  + a4 * b5  + a8 * b6,
                                  a0 * b8  + a4 * b9  + a8 * b10,
                                  a0 * b12 + a4 * b13 + a8 * b14 + a12,

                                  a1 * b0  + a5 * b1  + a9 * b2,
                                  a1 * b4  + a5 * b5  + a9 * b6,
                                  a1 * b8  + a5 * b9  + a9 * b10,
                                  a1 * b12 + a5 * b13 + a9 * b14 + a13,

                                  a2 * b0  + a6 * b1  + a10 * b2,
                                  a2 * b4  + a6 * b5  + a10 * b6,
                                  a2 * b8  + a6 * b9  + a10 * b10,
                                  a2 * b12 + a6 * b13 + a10 * b14 + a14
                              );
    }
    // As above, but writing results to the given output matrix.
    public static inline
    function multiplyAffineTo( a: AffineMatrix, b: AffineMatrix, out: AffineMatrix ) {
      // Avoid repeated property lookups by making access into the local frame.
      var a0 = a.e0;
      var a1 = a.e1; 
      var a2 = a.e2;
      var a4 = a.e4; 
      var a5 = a.e5; 
      var a6 = a.e6;
      var a8 = a.e8;
      var a9 = a.e9; 
      var a10 = a.e10;
      var a12 = a.e12;
      var a13 = a.e13; 
      var a14 = a.e14;
      var b0 = b.e0;
      var b1 = b.e1;
      var b2 = b.e2;
      var b4 = b.e4; 
      var b5 = b.e5; 
      var b6 = b.e6;
      var b8 = b.e8;
      var b9 = b.e9;
      var b10 = b.e10;
      var b12 = b.e12;
      var b13 = b.e13;
      var b14 = b.e14;

      out.e0 = a0 * b0  + a4 * b1  + a8 * b2;
      out.e4 = a0 * b4  + a4 * b5  + a8 * b6;
      out.e8 = a0 * b8  + a4 * b9  + a8 * b10;
      out.e12 = a0 * b12 + a4 * b13 + a8 * b14 + a12;
      out.e1 = a1 * b0  + a5 * b1  + a9 * b2;
      out.e5 = a1 * b4  + a5 * b5  + a9 * b6;
      out.e9 = a1 * b8  + a5 * b9  + a9 * b10;
      out.e13 = a1 * b12 + a5 * b13 + a9 * b14 + a13;
      out.e2 = a2 * b0  + a6 * b1  + a10 * b2;
      out.e6 = a2 * b4  + a6 * b5  + a10 * b6;
      out.e10 = a2 * b8  + a6 * b9  + a10 * b10;
      out.e14 = a2 * b12 + a6 * b13 + a10 * b14 + a14;
    }
    public static inline
    function makeIdentityAffine() {
        return AffineMatrix.matrix(
                                    1, 0, 0, 0,
                                    0, 1, 0, 0,
                                    0, 0, 1, 0
        );
    }
    public static inline
    function makeRotateAxisAngle( axis: Point3D, angle: Float ): AffineMatrix {
          var c = Math.cos( angle ); 
          var s = Math.sin( angle ); 
          var C = 1 - c;
          var xs = axis.x * s;
          var ys = axis.y * s;
          var zs = axis.z * s;
          var xC = axis.x * C;
          var yC = axis.y * C; 
          var zC = axis.z * C;
          var xyC = axis.x * yC;
          var yzC = axis.y * zC;
          var zxC = axis.z * xC;
          return AffineMatrix.matrix(
              axis.x * xC + c,        xyC - zs,          zxC + ys, 0,
              xyC + zs,        axis.y * yC + c,          yzC - xs, 0,
              zxC - ys,               yzC + xs,   axis.z * zC + c, 0);
    }

    // http://en.wikipedia.org/wiki/Rotation_matrix
    public static inline
    function makeRotateAffineX( theta: Float ): AffineMatrix {
          var s = Math.sin( theta );
          var c = Math.cos( theta );
          return AffineMatrix.matrix(
                                    1, 0,  0, 0,
                                    0, c, -s, 0,
                                    0, s,  c, 0
          );
    }
    public static inline
    function makeRotateAffineXTo( theta: Float, out: AffineMatrix ) {
        var s = Math.sin( theta );
        var c = Math.cos( theta );
        setAffineMatrix( out,
                                    1, 0,  0, 0,
                                    0, c, -s, 0,
                                    0, s,  c, 0
        );
    }
    public static inline
    function makeRotateAffineY( theta: Float ): AffineMatrix {
        var s = Math.sin( theta );
        var c = Math.cos( theta );
        return AffineMatrix.matrix(
                                    c, 0, s, 0,
                                    0, 1, 0, 0,
                                   -s, 0, c, 0
        );
    }
    public static inline
    function makeRotateAffineYTo( theta: Float, out: AffineMatrix ) {
        var s = Math.sin( theta );
        var c = Math.cos( theta );
        setAffineMatrix(  out,
                                    c, 0, s, 0,
                                    0, 1, 0, 0,
                                   -s, 0, c, 0);
    }
    public static inline
    function makeRotateAffineZ( theta: Float ): AffineMatrix {
        var s = Math.sin( theta );
        var c = Math.cos( theta );
        return AffineMatrix.matrix(
                                    c, -s, 0, 0,
                                    s,  c, 0, 0,
                                    0,  0, 1, 0
      );
    }
    public static inline
    function makeRotateAffineZTo( theta: Float, out: AffineMatrix ) {
        var s = Math.sin( theta );
        var c = Math.cos( theta );
        setAffineMatrix( out,
                                   c, -s, 0, 0,
                                   s,  c, 0, 0,
                                   0,  0, 1, 0);
    }
    public static inline
    function makeTranslateAffine( dx: Float, dy: Float, dz: Float ): AffineMatrix {
        return AffineMatrix.matrix(
            1, 0, 0, dx,
            0, 1, 0, dy,
            0, 0, 1, dz
        );
    }
    public static inline
    function makeScaleAffine( sx: Float, sy: Float, sz: Float ): AffineMatrix {
        return AffineMatrix.matrix(
            sx,  0,  0, 0,
             0, sy,  0, 0,
             0,  0, sz, 0
        );
    }

//     // Return the transpose of the inverse done via the classical adjoint.
//     // This skips division by the determinant, so transformations by the
//     // resulting transform will have to be renormalized.
//     function transAdjoint(a) {
//       var a0 = a.e0, a1 = a.e1, a2 = a.e2, a4 = a.e4, a5 = a.e5;
//       var a6 = a.e6, a8 = a.e8, a9 = a.e9, a10 = a.e10;
//       return new AffineMatrix(
//         a10 * a5 - a6 * a9,
//         a6 * a8 - a4 * a10,
//         a4 * a9 - a8 * a5,
//         0,
//         a2 * a9 - a10 * a1,
//         a10 * a0 - a2 * a8,
//         a8 * a1 - a0 * a9,
//         0,
//         a6 * a1 - a2 * a5,
//         a4 * a2 - a6 * a0,
//         a0 * a5 - a4 * a1,
//         0
//       );
//     }

    // Return the inverse of the rotation part of matrix a, assuming
    // that a is normalized.  This is just the transpose of the 3x3
    // rotation part.
    public static inline
    function invertNormalizedRotation( a: AffineMatrix ) {
        return AffineMatrix.matrix(
                                    a.e0, a.e1, a.e2,  0,
                                    a.e4, a.e5, a.e6,  0,
                                    a.e8, a.e9, a.e10, 0 );
    }

    // Return the inverse of the given affine matrix, assuming that
    // the rotation part is normalized, by exploiting
    // transpose==inverse for rotation matrix.
    public static inline
    function invertNormalized( a: AffineMatrix ) {
        var m = invertNormalizedRotation(a);
        var trans_prime = transformPoint( m, { x: a.e12, y: a.e13, z: a.e14 } );
        m.e12 = -trans_prime.x;
        m.e13 = -trans_prime.y;
        m.e14 = -trans_prime.z;
        return m;
    }
    public static inline
    function orthonormalizeRotation( a: AffineMatrix ){
        var new_x = Point3D.vectorNormalize( new Point3D( a.e0, a.e1, a.e2 ) );
        var new_z = Point3D.vectorNormalize( Point3D.crossProduct( new_x, new Point3D( a.e4, a.e5, a.e6 ) ) );
        var new_y = Point3D.crossProduct( new_z, new_x );
        a.e0 = new_x.x;
        a.e1 = new_x.y;
        a.e2 = new_x.z;
        a.e4 = new_y.x;
        a.e5 = new_y.y;
        a.e6 = new_y.z;
        a.e8 = new_z.x;
        a.e9 = new_z.y;
        a.e10 = new_z.z;
    }

    // Maps 0,0,0 to pos, maps x-axis to dir, maps y-axis to
    // up.  maps z-axis to the right.
    public static inline
    function makeOrientationAffine( pos: Point3D, dir: Point3D, up: Point3D ):AffineMatrix {
        var right = Point3D.crossProduct( dir, up );
        return AffineMatrix.matrix(
                                dir.x, up.x, right.x, pos.x,
                                dir.y, up.y, right.y, pos.y,
                                dir.z, up.z, right.z, pos.z
                              );
    }

    // Maps object dir (i.e. x) to -z, object right (i.e. z) to x,
    // object up (i.e. y) to y, object pos to (0,0,0).
    //
    // I.e. conventional OpenGL "Eye" coordinates.
    //
    // You would normally use this like:
    //
    //   var object_mat = jsgl.makeOrientationAffine(obj_pos, obj_dir, obj_up);
    //   var camera_mat = jsgl.makeOrientationAffine(cam_pos, cam_dir, cam_up);
    //   var view_mat = jsgl.makeViewFromOrientation(camera_mat);
    //   var proj_mat = jsgl.makeWindowProjection(win_width, win_height, fov);
    //
    //   // To draw object:
    //   context.setTransform(jsgl.multiplyAffine(proj_mat,
    //       jsgl.multiplyAffine(view_mat, object_mat));
    //   context.drawTris(verts, trilist);
    public static inline
    function makeViewFromOrientation( orient: AffineMatrix ) {
      // Swap x & z axes, negate z axis (even number of swaps
      // maintains right-handedness).
        var m = AffineMatrix.matrix(
                                    orient.e8,  orient.e4, -orient.e0, orient.e12,
                                    orient.e9,  orient.e5, -orient.e1, orient.e13,
                                    orient.e10, orient.e6, -orient.e2, orient.e14 
                                );
        return invertNormalized( m );
    }

    // Maps "Eye" coordinates into (preprojection) window coordinates.
    // Window coords:
    //    wz > 0  --> in front of eye, not clipped
    //    wz <= 0 --> behind eye; clipped
    //    [wx/wz,wy/wz] == [0,0] (at upper-left)
    //    [wx/wz,wy/wz] == [win_width,win_height] (at lower-right)
    //
    // (This is simplified, and different from OpenGL.)
    public static inline
    function makeWindowProjection( win_width: Float, win_height: Float, fov_x_radians: Float ): AffineMatrix {
        var half_width = win_width / 2;
        var half_height = win_height / 2;
        var tan_half = Math.tan(fov_x_radians / 2);
        var scale = half_width / tan_half;
        return AffineMatrix.matrix(
                                    scale, -0,                  -scale, 0,
                                    0, -scale, -half_height / tan_half, 0,
                                    0,      0,                      -1, 0
                                );
    }

}
