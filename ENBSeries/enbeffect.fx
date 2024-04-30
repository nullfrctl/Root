/*
 *  P e r c e p t r o n
 *  Coypright (c) MMXXIV  Santiago Velasquez.
 */

#define NOTORIOUS6_STANDARD 0
#define BRIGHTNESS_HUE_PRESERVING 1

#define TONE_MAPPING_MODE NOTORIOUS6_STANDARD

#include "libperceptron/types.fxh"
#include "libperceptron/sampling.fxh"
#include "libperceptron/vs.fxh"
#include "libperceptron/ps.fxh"
#include "libperceptron/enb.fxh"
#include "libperceptron/parameters.fxh"
#include "libblend/screen.fxh"

#include "libnotorious6/inc/ycbcr.hlsl"
#include "libnotorious6/inc/xyz.hlsl"
#include "libnotorious6/inc/standard_observer.hlsl"
#include "libnotorious6/inc/srgb.hlsl"
#include "libnotorious6/inc/math.hlsl"
#include "libnotorious6/inc/oklab.hlsl"
#include "libnotorious6/inc/luv.hlsl"
#include "libnotorious6/inc/lab.hlsl"
#include "libnotorious6/inc/ipt.hlsl"
#include "libnotorious6/inc/ictcp.hlsl"
#include "libnotorious6/inc/helmholtz_kohlrausch.hlsl"
#include "libnotorious6/inc/bezold_brucke.hlsl"

#if (TONE_MAPPING_MODE == NOTORIOUS6_STANDARD)
  #include "libnotorious6/inc/display_transform.hlsl"
#elif (TONE_MAPPING_MODE == BRIGHTNESS_HUE_PRESERVING)
  struct ShaderInput { RGB stimulus; };
  #include "libnotorious6/brightness-hue-preserving.glsl"
#endif

float U_exposure <
  string UIName = "Exposure";
  string UIWidget = "Spinner";
  float UIStep = 1/3;
> = 0;

static const float MIDDLE_GREY = 0.18;
static const float FLOOR = MIDDLE_GREY * exp2(-16);

RGBA perceptron_PS(PS i) : SV_target {
  RGB C = sample(T_C, S_R, i.v.c.xy).rgb;

  /* Bloom. */
  RGB C_B = sample(T_B, S_R, i.v.c.xy).rgb;
  C = lerp(C, C_B, 0.1);

  /* Vignette. */
  float c_n = length((i.v.c.xy - 0.5) * float2(1,ScreenSize.w));
  C *= exp(-4*c_n*c_n);

  /* Automatic exposure adaptation.  */
  float g = sample(T_A, S_R, i.v.c.xy).x;
  float k_A = clamp(MIDDLE_GREY / (g + FLOOR), G_P.A_min, G_P.A_max);
  C *= k_A;

  /* Manual exposure offset. */
  C *= exp2(U_exposure);

  /* Tone map. */
  {
    // we need to do this to avoid NaNs. 16 stops below middle grey is enough.
    C = max(C, FLOOR);

    #if (TONE_MAPPING_MODE == NOTORIOUS6_STANDARD)
      C = display_transform_sRGB(C);
      C = max(C,0);
    #elif (TONE_MAPPING_MODE == BRIGHTNESS_HUE_PRESERVING)
      ShaderInput S = { C };
      C = compress_stimulus(S);
    #endif
  }

  // color grading.
  {
    float3 C_p = linear_to_perceptual(C);

    // apply saturation.
    C_p.yz *= G_P.I_saturation;

    // apply tint.
    C_p.yz = lerp(C_p.yz, C_p.yz * linear_to_perceptual(G_P.I_tint.rgb).yz, G_P.I_tint.a);

    // apply brightness.
    C_p.x *= G_P.I_brightness;

    // apply contrast.
    //C_p.x = lerp(linear_to_perceptual(g).x, C_p.x, G_P.I_contrast);
    C_p.x = lerp(linear_to_perceptual(0.18).x, C_p.x, G_P.I_contrast);

    // apply fade.
    C_p.yz = lerp(C_p.yz, linear_to_perceptual(G_P.I_fade.rgb).yz, G_P.I_fade.a);

    C = perceptual_to_linear(C_p);
  }

  // output.
  return RGBA(sRGB_OETF(C), 1);
}

technique11 Draw < string UIName="Perceptron"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, triangle_VS()));
    SetPixelShader(CompileShader(ps_5_0, perceptron_PS()));
  }
}