#ifndef __LIBPERCEPTRON_CONSTANTS__
#define __LIBPERCEPTRON_CONSTANTS__

#include "operations.fxh"

/* Euler's number is `exp(1)' because the `exp x' function is defined as `e^x.'
   Therefore, `e^1' and thus `exp(1)' must be `e.' */
static const float e = exp(1);

/* Pi is equal to the arccosine of -1. */
static const float pi = arccos(-1);

#endif