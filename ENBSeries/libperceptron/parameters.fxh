#ifndef __LIBPERCEPTRON_PARAMETERS__
#define __LIBPERCEPTRON_PARAMETERS__

#include "enb.fxh"

struct P {
  /* Params01[1].X, Y, and Z. */
  float A_max;
  float A_min;
  float A_k;

  /* Params01[2].X, Z, and W. */
  float I_saturation; 
  float I_contrast;
  float I_brightness;

  /* Params01[3] */
  float4 I_tint;

  /* Params01[4].ZW */
  float2 k_bloom;

  /* Params01[5] */
  float4 I_fade;
};

static const P G_P = { 
  // adaptation stuff.
  Params01[1].x, Params01[1].y, Params01[1].z,

  // imagespace parameters.
  Params01[2].x, Params01[2].z, Params01[2].w,

  // imagespace tint.
  Params01[3].rgba,

  // bloom sampling offset.
  Params01[4].zw,

  // imagespace fade.
  Params01[5].rgba
};

#endif