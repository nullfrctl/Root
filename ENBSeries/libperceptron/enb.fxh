#ifndef __LIBPERCEPTRON_ENB__
#define __LIBPERCEPTRON_ENB__

/*
 * Parameters
 */

/* Timer.X: Generic timer in range [0, 1] in a period of 16 777 216 ms (4.6 hours);
   Timer.Y: Average frames per second;
   Timer.W: Frame-time elapsed (in S). */
float4 Timer;

/* ScreenSize.X: Width of viewport;
   ScreenSize.Y: Reciprocal of the former;
   ScreenSize.Z: Aspect ratio (w/h); 
   ScreenSize.W: Reciprocal of the former. */
float4 ScreenSize;

/* Shorthand for viewport dimensions. 
   V0: Width of the viewport;
   V1: Height of the viewport. */
static const float2 V = float2(ScreenSize.x, ScreenSize.x * ScreenSize.w);

/* Relative dimensions of a single pixel. "D_p" stands for Δp (letter delta, subscript 'p'). 
   Δp[0] = Width of a horizontal pixel;
   Δp[1] = Height of a vertical pixel. */
static const float2 D_p = float2(1/V[0], 1/V[1]);

/* Weather.X: Current weather index;
   Weather.Y: Outgoing weather index;
   Weather.Z: Weather transition;
   Weather.W: Time of day in 24 hours. */
float4 Weather;

float4 TimeOfDay1;
float4 TimeOfDay2;

/* T_D[0]: Dawn;
   T_D[1]: Sunrise;
   T_D[2]: Day;
   T_D[3]: Sunset;
   T_D[4]: Dusk;
   T_D[5]: Night. */
static const float T_D[6] = { TimeOfDay1.x, TimeOfDay1.y, TimeOfDay1.z, TimeOfDay1.w, TimeOfDay2.x, TimeOfDay2.y };

/* Range [0,1]. A value of zero means night; of one means day. */
float ENightDayFactor;
static const float grad_ND = ENightDayFactor;

/* Fallout 4 parameters. */
float4 Params01[7];

/* ENBParams01.X: Bloom amount.
   ENBParams01.Y: Lens amount. */
float4 ENBParams01;

static const float k_B = ENBParams01.x;
static const float K_L = ENBParams01.y;

/* DofParameters.Z: `ApertureTime' multiplied by time elapsed;
   DofParameters.W: `FocusingTime' multiplied by time elapsed. */
float4 DofParameters;

/* AdaptationParameters.X: Variable for `AdaptationMin;'
   AdaptationParameters.Y: Variable for `AdaptationMax;'
   AdaptationParameters.Z: Variable for `AdaptationSensitivity;'
   AdaptationParameters.W: `Adaptationtime' multiplied by time elapsed. */
float4 AdaptationParameters;


/*
 * Textures
 */

/* RGBA16 or RGB10A2; 1024 x 1024 dimensions. */
Texture2D TextureDownsampled;

/* Current frame's focus depth or aperture. Not used in DOF. */
Texture2D TextureCurrent;

/* Previous frame's focus depth or aperture. Not used in DOF. */
Texture2D TexturePrevious;

/* HDR color. In multipass modes, it's the previous pass' 32-bit SDR; except when RTs are used. */
Texture2D TextureColor;
#define T_C TextureColor

/* Vanilla or ENB bloom. */
Texture2D TextureBloom;
#define T_B TextureBloom

/* ENB Lens effects. */
Texture2D TextureLens;

/* Scene depth or z-buffer. */
Texture2D TextureDepth;

/* Blue noise. */
Texture2D TextureJitter;

/* Normal maps. */
Texture2D TextureNormal;

/* Vanilla or ENB adaptation */
Texture2D TextureAdaptation;
#define T_A TextureAdaptation

/* Aperture for current frame. R32F; computed in DOF shader. */
Texture2D TextureAperture;

/* ENB palette texture. */
Texture2D TexturePalette;

/*
 * Textures, Multipass.
 */

//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D TextureOriginal; //color R16B16G16A16 64 bit hdr format
Texture2D RenderTarget1024; //R16B16G16A16F 64 bit hdr format, 1024*1024 size
Texture2D RenderTarget512; //R16B16G16A16F 64 bit hdr format, 512*512 size
Texture2D RenderTarget256; //R16B16G16A16F 64 bit hdr format, 256*256 size
Texture2D RenderTarget128; //R16B16G16A16F 64 bit hdr format, 128*128 size
Texture2D RenderTarget64; //R16B16G16A16F 64 bit hdr format, 64*64 size
Texture2D RenderTarget32; //R16B16G16A16F 64 bit hdr format, 32*32 size
Texture2D RenderTarget16; //R16B16G16A16F 64 bit hdr format, 16*16 size
Texture2D RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format
Texture2D RenderTargetRGBA64; //R16B16G16A16 64 bit ldr format
Texture2D RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D RenderTargetR16F; //R16F 16 bit hdr format with red channel only
Texture2D RenderTargetR32F; //R32F 32 bit hdr format with red channel only
Texture2D RenderTargetRGB32F; //32 bit hdr format without alpha

#endif