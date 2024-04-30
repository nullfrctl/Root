#ifndef __LIBPERCEPTRON_VS__
#define __LIBPERCEPTRON_VS__

struct VS {
  float4 P : SV_position;
  float4 c : texcoord;
};

void triangle_VS(inout VS v, in uint i : SV_vertexID)
{
  v.c.x = (i == 2) ? 2.0 : 0.0;
  v.c.y = (i == 1) ? 2.0 : 0.0;

  v.P = float4(v.c.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

#endif