// jsgl.js
// Author: tu@tulrich.com (Thatcher Ulrich)
//
// Simple immediate-mode 3D graphics API in pure Javascript.  Uses
// canvas2d for rasterization.
//
// matrix & vector math & V8 tricks stolen from Dean McNamee's Soft3d.js
//
// WARNING: I reordered/renumbered his matrix elements to match OpenGL
// conventions.
//
// Also, if it helps understand the code: in my mind, vectors are
// column vectors, and a transform is "Mx" where M is the matrix and x
// is the vector.
// 
//  Ported to Haxe by Nanjizal 20 March 2018 ( fixes 14 July )
//