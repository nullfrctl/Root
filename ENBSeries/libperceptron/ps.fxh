#ifndef __LIBPERCEPTRON_PS__
#define __LIBPERCEPTRON_PS__

#include "types.fxh"
#include "vs.fxh"
#include "sampling.fxh"

struct PS {
  VS v;
};

float4 blank_PS(in PS i, in Texture2D T) : SV_target {
  return sample(T, S_R, i.v.c);
}

#endif