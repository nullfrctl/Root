// ----------------------------------------------------------------------------------------------------------
// REFORGED BLOOM BY THE SANDVICH MAKER

// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
// hereby granted.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
// INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
// OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ----------------------------------------------------------------------------------------------------------



// ----------------------------------------------------------------------------------------------------------
// PRE-PROCESSOR USER-EDITABLES
// ----------------------------------------------------------------------------------------------------------
// change the min and max selectable filter sizes in the UI
#define GAUSSIAN_MIN_FILTER_SIZE 4
#define GAUSSIAN_MAX_FILTER_SIZE 16

// comment this to hide/disable the texture multipliers
// #define USE_TEXTURE_MULTIPLIERS



// ----------------------------------------------------------------------------------------------------------
// UI MULTIPARAMETER OPTIONS
// These defines represent various UI options available in the ENB menu. Change them to any of the following
// options to have separate parameters for different times of day and/or locations:

// SINGLE (it's just the one parameter)
// EI (Exterior: Single, Interior: Single)
// DN (Day/Night)
// DNI / DN_I (Exterior: Day/Night, Interior: Single)
// DNE_DNI (Exterior: Day/Night, Interior: Day/Night)
// TOD (Dawn/Sunrise/Day/Dusk/Sunset/Night)
// TODI / TOD_I (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Single)
// TODE_DNI (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Day/Night)
// TODE_TODI (Exterior: Dawn/Sunrise/Day/Dusk/Sunset/Night, Interior: Dawn/Sunrise/Day/Dusk/Sunset/Night)

// But avoid setting boolean and integer parameters to anything other than SINGLE and EI to avoid jarring
// transitions between states.
// Also note that the overhead for using a lot of complex interpolators that are required for options like
// the TOD ones is not free, so try to hold back using them too much unless you really need them.
// ----------------------------------------------------------------------------------------------------------
#define UI_THRESHOLD SINGLE

#define UI_MULTIPLIER1 SINGLE
#define UI_MULTIPLIER2 SINGLE
#define UI_MULTIPLIER3 SINGLE
#define UI_MULTIPLIER4 SINGLE
#define UI_MULTIPLIER5 SINGLE
#define UI_MULTIPLIER6 SINGLE



// ----------------------------------------------------------------------------------------------------------
// VV SHADER STARTS HERES VV
// ----------------------------------------------------------------------------------------------------------
#define REFORGED_HLSL_5 1
#define REFORGED_INCLUDE_FILTERS 1
#define HDR_MAX 16384.0


#include "Reforged/common.fxh"



// ----------------------------------------------------------------------------------------------------------
// EXTERNAL PARAMETERS¹
// ----------------------------------------------------------------------------------------------------------
// x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4 Timer;
// x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4 ScreenSize;
// changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float AdaptiveQuality;
// x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4 Weather;
// x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4 TimeOfDay1;
// x = dusk, y = night. Interpolators range from 0..1
float4 TimeOfDay2;
// changes in range 0..1, 0 means that night time, 1 - day time
float ENightDayFactor;
// changes 0 or 1. 0 means that exterior, 1 - interior
float EInteriorFactor;



// ----------------------------------------------------------------------------------------------------------
// CONSTS
// ----------------------------------------------------------------------------------------------------------
static const float2 PixSize = float2(ScreenSize.y, ScreenSize.y * ScreenSize.z);



// ----------------------------------------------------------------------------------------------------------
// ENB UI
// ----------------------------------------------------------------------------------------------------------
// ¹: macros.fxh has to be included after external parameters have been defined.
#include "Reforged/macros.fxh"


#define UI_VAR_PREFIX_MODE NO_PREFIX

#define UI_CATEGORY Credits
UI_SEPARATOR_CUSTOM("Reforged Bloom Lite")
UI_MESSAGE(Credits1, "by The Sandvich Maker")

UI_WHITESPACE(1)

UI_INT(GaussianFilterSize, "Filter Size", GAUSSIAN_MIN_FILTER_SIZE, GAUSSIAN_MAX_FILTER_SIZE, 6)

UI_WHITESPACE(2)

UI_FLOAT_MULTI(UI_THRESHOLD, Threshold, "Threshold", 0.0, 4.0, 0.0)

UI_WHITESPACE(3)

#ifndef USE_TEXTURE_MULTIPLIERS
    #define USE_TEXTURE_MULTIPLIERS static const
#endif
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER1, Multiplier1, "512x512 Multiplier", 1.0, 1.0, 1.0)
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER2, Multiplier2, "256x256 Multiplier", 1.0, 1.0, 1.0)
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER3, Multiplier3, "128x128 Multiplier", 1.0, 1.0, 1.0)
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER4, Multiplier4, "64x64 Multiplier", 1.0, 1.0, 1.0)
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER5, Multiplier5, "34x32 Multiplier", 1.0, 1.0, 1.0)
USE_TEXTURE_MULTIPLIERS UI_FLOAT3_MULTI(UI_MULTIPLIER6, Multiplier6, "16x16 Multiplier", 1.0, 1.0, 1.0)



// ----------------------------------------------------------------------------------------------------------
// TEMP PARAMETERS
// ----------------------------------------------------------------------------------------------------------
// keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4 tempF1; //0,1,2,3
float4 tempF2; //5,6,7,8
float4 tempF3; //9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4 tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4 tempInfo2;



// ----------------------------------------------------------------------------------------------------------
// TEXTURES
// ----------------------------------------------------------------------------------------------------------
Texture2D TextureDownsampled; // color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format. 1024*1024 size
Texture2D TextureColor; // color which is output of previous technique (except when drawed to temporary render target), R16B16G16A16 64 bit hdr format. 1024*1024 size

Texture2D TextureOriginal; // color R16B16G16A16 64 bit or R11G11B10 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D TextureDepth; // scene depth R32F 32 bit hdr format, screen size. PLEASE AVOID USING IT BECAUSE OF ALIASING ARTIFACTS, UNLESS YOU FIX THEM
Texture2D TextureAperture; // this frame aperture 1*1 R32F hdr red channel only. computed in PS_Aperture of enbdepthoffield.fx

// temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D RenderTarget1024; // R16B16G16A16F 64 bit hdr format, 1024*1024 size
Texture2D RenderTarget512; // R16B16G16A16F 64 bit hdr format, 512*512 size
Texture2D RenderTarget256; // R16B16G16A16F 64 bit hdr format, 256*256 size
Texture2D RenderTarget128; // R16B16G16A16F 64 bit hdr format, 128*128 size
Texture2D RenderTarget64; // R16B16G16A16F 64 bit hdr format, 64*64 size
Texture2D RenderTarget32; // R16B16G16A16F 64 bit hdr format, 32*32 size
Texture2D RenderTarget16; // R16B16G16A16F 64 bit hdr format, 16*16 size
Texture2D RenderTargetRGBA32; // R8G8B8A8 32 bit ldr format, screen size
Texture2D RenderTargetRGBA64F; // R16B16G16A16F 64 bit hdr format, screen size
// Not available in enbbloom.fx:
    // Texture2D RenderTargetRGBA64; // R16B16G16A16 64 bit ldr format
    // Texture2D RenderTargetR16F; // R16F 16 bit hdr format with red channel only
    // Texture2D RenderTargetR32F; // R32F 32 bit hdr format with red channel only
    // Texture2D RenderTargetRGB32F; // 32 bit hdr format without alpha

#define RT(x) RenderTarget##x



// ----------------------------------------------------------------------------------------------------------
// SAMPLERS
// ----------------------------------------------------------------------------------------------------------
SamplerState SamplerPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};
SamplerState SamplerLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
SamplerState SamplerBorder
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Border;
    AddressV = Border;
    BorderColor = float4(0.0, 0.0, 0.0, 1.0);
};



// ----------------------------------------------------------------------------------------------------------
// STRUCTS
// ----------------------------------------------------------------------------------------------------------
struct VS_INPUT
{
    float3 pos : POSITION;
    float2 txcoord : TEXCOORD0;
};
struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float2 txcoord : TEXCOORD0;
};



// ----------------------------------------------------------------------------------------------------------
// VERTEX SHADER
// ----------------------------------------------------------------------------------------------------------
VS_OUTPUT VS_Quad(VS_INPUT IN)
{
    VS_OUTPUT OUT;
    OUT.pos = float4(IN.pos.xyz, 1.0);
    OUT.txcoord.xy = IN.txcoord.xy;
    return OUT;
}


VS_OUTPUT VS_Scaled(VS_INPUT IN, uniform float scale)
{
    VS_OUTPUT OUT;
    OUT.pos = float4(IN.pos.xyz, 1.0);
    OUT.txcoord.xy = IN.txcoord.xy * scale;
    return OUT;
}



// ----------------------------------------------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------------------------------------------
float4 gaussianFilter(rfTexture2D tex, float2 axis, float2 uv, float2 pixsize, float filtersize)
{
    axis *= pixsize;

    filtersize = round(max(4.0, filtersize));
    float o = -rcp(filtersize * filtersize);

    float4 sum = 0.0;

    for (float i = -filtersize; i <= filtersize; i++)
    {
        float offset = i * 2.0 - 0.5;
        float2 sampleUV = float2(uv + axis * offset);

        float weight = exp(offset * offset * o);
        float4 curr = tex.SampleLevel(SamplerBorder, sampleUV, 0);

        sum.xyz += curr.xyz * weight;
        sum.w += weight;
    }
    sum.xyz /= sum.w + 0.0001;

    return sum;
}



// ----------------------------------------------------------------------------------------------------------
// PIXEL SHADERS
// ----------------------------------------------------------------------------------------------------------
float4 PS_Downsample(VS_OUTPUT IN, uniform Texture2D tex, uniform float texscale) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res = filterJimenez(tex, uv, texscale);
    if (Threshold > 0.0)
    {
        res.w = max3(res.xyz);
        res.xyz /= res.w + 1e-6;
        res.w = max(0.0, res.w - Threshold);
        res.xyz *= res.w;
    }
    return res;
}


float4 PS_GaussianHori(VS_OUTPUT IN, uniform Texture2D tex, uniform float texscale) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    if (min2(1.1 - uv) < 0.0) return 0.0;
    return gaussianFilter(tex, float2(1.0, 0.0), uv, texscale, GaussianFilterSize);
}


float4 PS_GaussianVert(VS_OUTPUT IN, uniform Texture2D tex, uniform float scale, uniform float texscale) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    return gaussianFilter(tex, float2(0.0, 1.0), uv * scale, texscale, GaussianFilterSize * ScreenSize.z);
}


float4 PS_GaussianCombine(VS_OUTPUT IN, float4 co : SV_Position0) : SV_Target
{
    float2 uv = IN.txcoord.xy;
    float4 res = 0.0;

    static const float texscale = 1.0 / 512.0;
    res.xyz += filter4x4(RenderTarget512, uv, texscale).xyz        * Multiplier1;
    res.xyz += filter4x4(RenderTarget256, uv, texscale * 2.0).xyz  * Multiplier2;
    res.xyz += filter4x4(RenderTarget128, uv, texscale * 4.0).xyz  * Multiplier3;
    res.xyz += filter4x4(RenderTarget64,  uv, texscale * 8.0).xyz  * Multiplier4;
    res.xyz += filter4x4(RenderTarget32,  uv, texscale * 16.0).xyz * Multiplier5;
    res.xyz += filter4x4(RenderTarget16,  uv, texscale * 32.0).xyz * Multiplier6;
    res.xyz /= Multiplier1 + Multiplier2 + Multiplier3
             + Multiplier4 + Multiplier5 + Multiplier6 + 1e-6;

    res.w = 1.0;
    return min(res, HDR_MAX);
}


// ----------------------------------------------------------------------------------------------------------
// TECHNIQUES
// ----------------------------------------------------------------------------------------------------------
TECHNIQUE_NAMED_TARGETED(GaussianII, "Reforged Bloom Lite", RT(512), VS_Quad(), PS_Downsample(TextureDownsampled, 1.0/1024.0))
TECHNIQUE         (GaussianII1,           VS_Scaled(2),  PS_GaussianHori(RT(512),                1.0/512.0))
TECHNIQUE_TARGETED(GaussianII2,  RT(512), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/2.0,  1.0/1024.0))
TECHNIQUE         (GaussianII3,           VS_Scaled(4),  PS_GaussianHori(RT(512),                1.0/256.0))
TECHNIQUE_TARGETED(GaussianII4,  RT(256), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/4.0,  1.0/1024.0))
TECHNIQUE         (GaussianII5,           VS_Scaled(8),  PS_GaussianHori(RT(256),                1.0/128.0))
TECHNIQUE_TARGETED(GaussianII6,  RT(128), VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/8.0,  1.0/1024.0))
TECHNIQUE         (GaussianII7,           VS_Scaled(16), PS_GaussianHori(RT(128),                1.0/64.0))
TECHNIQUE_TARGETED(GaussianII8,  RT(64),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/16.0, 1.0/1024.0))
TECHNIQUE         (GaussianII9,           VS_Scaled(32), PS_GaussianHori(RT(64),                 1.0/32.0))
TECHNIQUE_TARGETED(GaussianII10, RT(32),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/32.0, 1.0/1024.0))
TECHNIQUE         (GaussianII11,          VS_Scaled(64), PS_GaussianHori(RT(32),                 1.0/16.0))
TECHNIQUE_TARGETED(GaussianII12, RT(16),  VS_Quad(),     PS_GaussianVert(TextureColor, 1.0/64.0, 1.0/1024.0))
TECHNIQUE(GaussianII13, VS_Quad(), PS_GaussianCombine())