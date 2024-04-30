#include "libperceptron/enb.fxh"
#include "libperceptron/sampling.fxh"
#include "libperceptron/types.fxh"
#include "libperceptron/vs.fxh"
#include "libperceptron/ps.fxh"

int U_size <
  string UIName = "Filter Size";
  int UIMin = 4;
  int UIMax = 16;
  string UIWidget = "Spinner";
> = 4;

RGBA downsample_PS(PS i, uniform Texture2D T, uniform float s) : SV_target {
  return filter_jimenez(T, i.v.c.xy, s);
}

RGBA gaussian_h_PS(PS i, uniform Texture2D T, uniform float t_s) : SV_target {
  return filter_gaussian(T, float2(1,0), i.v.c.xy, t_s, U_size);
}

RGBA gaussian_v_PS(PS i, uniform Texture2D T, uniform float s, uniform float t_s) : SV_target {
  return filter_gaussian(T, float2(0,1), i.v.c.xy*s, t_s, U_size * ScreenSize.z);
}

RGBA gaussian_combine_PS(PS i) : SV_target {
  float2 c = i.v.c.xy;
  float4 o = 0;

  static const float t_s = 1/512;
  o.rgb += filter_tent3x3(RenderTarget512, c, t_s * 1 ).rgb;
  o.rgb += filter_tent3x3(RenderTarget256, c, t_s * 2 ).rgb;
  o.rgb += filter_tent3x3(RenderTarget128, c, t_s * 4 ).rgb;
  o.rgb += filter_tent3x3(RenderTarget64,  c, t_s * 8 ).rgb;
  o.rgb += filter_tent3x3(RenderTarget32,  c, t_s * 16).rgb;
  o.rgb += filter_tent3x3(RenderTarget16,  c, t_s * 32).rgb;

  o.rgb /= 6;
  o.a = 1;

  return o;
}

void scaled_VS(inout VS v, uniform float scale)
{
    v.P.w = 1.0;
    v.c.xy *= scale;
}

technique gaussian0 < string UIName = "Perceptron"; string RenderTarget = "RenderTarget512"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, downsample_PS(TextureDownsampled, 1./1024.)));
  }
}

technique gaussian1H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(2)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget512, 1./512.)));
  }
}

technique gaussian1V < string RenderTarget = "RenderTarget512"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./2., 1./1024.)));
  }
}

technique gaussian2H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(4)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget512, 1./256.)));
  }
}

technique gaussian2V < string RenderTarget = "RenderTarget256"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./4., 1./1024.)));
  }
}

technique gaussian3H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(8)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget256, 1./128.)));
  }
}

technique gaussian3V < string RenderTarget = "RenderTarget128"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./8., 1./1024.)));
  }
}

technique gaussian4H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(16)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget128, 1./64.)));
  }
}

technique gaussian4V < string RenderTarget = "RenderTarget64"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./16., 1./1024.)));
  }
}

technique gaussian5H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(32)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget64, 1./32.)));
  }
}

technique gaussian5V < string RenderTarget = "RenderTarget32"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./32., 1./1024.)));
  }
}

technique gaussian6H {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(64)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_h_PS(RenderTarget32, 1./16.)));
  }
}

technique gaussian6V < string RenderTarget = "RenderTarget16"; > {
  pass {
    SetVertexShader(CompileShader(vs_5_0, scaled_VS(1)));
    SetPixelShader(CompileShader(ps_5_0, gaussian_v_PS(TextureColor, 1./64., 1./1024.)));
  }
}

technique gaussian7 {
  pass {
    SetVertexShader(CompileShader(vs_5_0, triangle_VS()));
    SetPixelShader(CompileShader(ps_5_0, gaussian_combine_PS()));
  }
}