#ifndef __LIBBLEND_SCREEN__
#define __LIBBLEND_SCREEN__

float3 blend_screen(float3 C1, float3 C2) {
  float3 C0 = 1 - ((1 - C1) * (1 - C2));
  return C0;
}

float3 blend_screen_hdr(float3 C1, float3 C2) {
  float3 C0 = C1 + (C2 / (1 + C1));
  return C0;
}

#endif