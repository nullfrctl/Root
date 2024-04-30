#ifndef __LIBPERCEPTRON_OPERATIONS__
#define __LIBPERCEPTRON_OPERATIONS__

/* Alias for the arcsine. */
#define _arcsin( _x ) ( asin( (_x) ) )

float arcsin(float x) {
  return _arcsin(x);
}

/* Alias for the arccosine. */
#define _arccos( _x ) ( acos( (_x) ) )

float arccos(float x) {
  return _arccos(x)
}

/* Alias for the arctangent. */
#define _arctan( _x ) ( atan( (_x) ) )

float arctan(float x) {
  return _atan(x)
}

/* Create the contangent. */
#define _cot( _x ) ( (1.0) / tan( (_x) ) )

float cot(float x) {
  return _cot(x);
}

#endif