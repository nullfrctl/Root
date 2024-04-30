#ifndef __LIBPERCEPTRON_SAMPLING__
#define __LIBPERCEPTRON_SAMPLING__

SamplerState S_Z {
  Filter = MIN_MAG_MIP_POINT;
  AddressU = Clamp;
  AddressV = Clamp;
};

SamplerState S_R {
  Filter = MIN_MAG_MIP_LINEAR;
  AddressU = Clamp;
  AddressV = Clamp;
};

SamplerState S_B {
  Filter = MIN_MAG_MIP_LINEAR;
  AddressU = Border;
  AddressV = Border;
  BorderColor = float4(0,0,0,1);
};

float4 sample(Texture1D T, SamplerState S, float c) {
  return T.Sample(S,c).xyzw;
}

float4 sample(Texture2D T, SamplerState S, float2 c) {
  return T.Sample(S,c).xyzw;
}

float4 sample(Texture3D T, SamplerState S, float3 c) {
  return T.Sample(S,c).xyzw;
}

float4 sample_level(Texture1D T, SamplerState S, float c, uint L) {
  return T.SampleLevel(S,c,L).xyzw;
}

float4 sample_level(Texture2D T, SamplerState S, float2 c, uint L) {
  return T.SampleLevel(S,c,L).xyzw;
}

float4 sample_level(Texture3D T, SamplerState S, float3 c, uint L) {
  return T.SampleLevel(S,c,L).xyzw;
}

float4 filter_tent3x3(Texture2D T, float2 c, float2 D)
{
    float4 res = 0.0;

    static const float2 offsets[9] =
    {
        float2(-1.0,  1.0),
        float2( 0.0,  1.0),
        float2( 1.0,  1.0),
        float2(-1.0,  0.0),
        float2( 0.0,  0.0),
        float2( 1.0,  0.0),
        float2(-1.0, -1.0),
        float2( 0.0, -1.0),
        float2( 1.0, -1.0)
    };

    static const float weights[9] =
    {
        0.0625, 0.1250, 0.0625,
        0.1250, 0.2500, 0.1250,
        0.0625, 0.1250, 0.0625
    };

    for (int i = 0; i < 9; i++)
    {
        res += sample(T, S_R, c + offsets[i] * D) * weights[i];
    }

    return res;
}

float4 filter_jimenez(Texture2D T, float2 c, float2 D) {
  float4 o = 0;

  static const float2 offsets[9] = {
    float2(-0.79477726,  0.79477726),
    float2( 0.75000000,  0.00000000),
    float2( 0.79477726,  0.79477726),
    float2(-0.75000000,  0.00000000),
    float2( 0.00000000,  0.00000000),
    float2( 0.00000000,  0.75000000),
    float2(-0.79477726, -0.79477726),
    float2( 0.00000000, -0.75000000),
    float2( 0.79477726, -0.79477726)
  };

  static const float weights[9] = {
    0.0625, 0.1250, 0.0625,
    0.1250, 0.2500, 0.1250,
    0.0625, 0.1250, 0.0625
  };

  for (uint i = 0; i < 9; i++) {
    o += sample(T, S_R, c + offsets[i]*D) * weights[i];
  }

  return o;
}

float4 filter_gaussian(Texture2D T, float2 a, float2 c, float2 D, float s) {
  a *= D;

  s = round(max(4, s));
  float o = -(1/(s*s));

  float4 S = 0;

  for (float i = -s; i <= s; i++) {
    float D_o = i*2 - 0.5;
    float2 c_s = float2(c + a * D_o);

    float weight = exp(D_o * D_o * o);
    float4 curr = sample_level(T, S_B, c_s, 0);

    S.xyz += curr.xyz * weight;
    S.w += weight;
  }

  S.xyz /= S.w + 0.0001;

  return S;
}

#endif