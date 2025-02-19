#line 2

// Remove this line below if you plan to modify this file
#ifndef EAGLER_IS_GLES_200
#define USE_OPTIMIZED
#endif


/*
 * Copyright (c) 2022-2024 lax1dude. All Rights Reserved.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * 
 */


/*
 * This file was modified by lax1dude to remove dead code
 * 
 * Original: https://gist.github.com/kosua20/0c506b81b3812ac900048059d2383126
 * 
 */


/*
 * ============================================================================
 * 
 * 
 *                     NVIDIA FXAA 3.11 by TIMOTHY LOTTES
 * 
 * 
 * ------------------------------------------------------------------------------
 * COPYRIGHT (C) 2010, 2011 NVIDIA CORPORATION. ALL RIGHTS RESERVED.
 * ------------------------------------------------------------------------------
 * TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
 * *AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
 * OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL NVIDIA
 * OR ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR
 * CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
 * LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
 * OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE
 * THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGES.
 * 
 */

EAGLER_IN(vec2, v_position2f)

EAGLER_FRAG_OUT()

uniform sampler2D u_screenTexture;
uniform vec2 u_screenSize2f;

#ifndef USE_OPTIMIZED
#ifndef FXAA_GREEN_AS_LUMA
    // For those using non-linear color,
    // and either not able to get luma in alpha, or not wanting to,
    // this enables FXAA to run using green as a proxy for luma.
    // So with this enabled, no need to pack luma in alpha.
    //
    // This will turn off AA on anything which lacks some amount of green.
    // Pure red and blue or combination of only R and B, will get no AA.
    //
    // Might want to lower the settings for both,
    //    fxaaConsoleEdgeThresholdMin
    //    fxaaQualityEdgeThresholdMin
    // In order to insure AA does not get turned off on colors 
    // which contain a minor amount of green.
    //
    // 1 = On.
    // 0 = Off.
    //
    #define FXAA_GREEN_AS_LUMA 0
#endif

#ifndef FXAA_DISCARD
    // 1 = Use discard on pixels which don't need AA.
    // 0 = Return unchanged color on pixels which don't need AA.
    #define FXAA_DISCARD 0
#endif

/*============================================================================
                                API PORTING
============================================================================*/
    #define FxaaBool bool
    #define FxaaDiscard discard
    #define FxaaFloat float
    #define FxaaFloat2 vec2
    #define FxaaFloat3 vec3
    #define FxaaFloat4 vec4
    #define FxaaHalf float
    #define FxaaHalf2 vec2
    #define FxaaHalf3 vec3
    #define FxaaHalf4 vec4
    #define FxaaInt2 ivec2
    #define FxaaSat(x) clamp(x, 0.0, 1.0)
    #define FxaaTex sampler2D
/*--------------------------------------------------------------------------*/

    #define FxaaTexTop(t, p) EAGLER_TEXTURE_2D_LOD(t, p, 0.0)

/*============================================================================
                   GREEN AS LUMA OPTION SUPPORT FUNCTION
============================================================================*/
#if (FXAA_GREEN_AS_LUMA == 0)
    FxaaFloat FxaaLuma(FxaaFloat4 rgba) { return dot(rgba.xyz * rgba.xyz, vec3(0.299, 0.587, 0.114)); }
#else
    FxaaFloat FxaaLuma(FxaaFloat4 rgba) { return rgba.y; }
#endif    

/*============================================================================
                         FXAA3 CONSOLE - PC VERSION
============================================================================*/
/*--------------------------------------------------------------------------*/
FxaaFloat4 FxaaPixelShader(
    // See FXAA Quality FxaaPixelShader() source for docs on Inputs!
    //
    // Use noperspective interpolation here (turn off perspective interpolation).
    // {xy} = center of pixel
    FxaaFloat2 pos,
    //
    // Used only for FXAA Console, and not used on the 360 version.
    // Use noperspective interpolation here (turn off perspective interpolation).
    // {xy__} = upper left of pixel
    // {__zw} = lower right of pixel
    FxaaFloat4 fxaaConsolePosPos,
    //
    // Input color texture.
    // {rgb_} = color in linear or perceptual color space
    // if (FXAA_GREEN_AS_LUMA == 0)
    //     {___a} = luma in perceptual color space (not linear)
    FxaaTex tex,
    //
    // Only used on FXAA Console.
    // This must be from a constant/uniform.
    // This effects sub-pixel AA quality and inversely sharpness.
    //   Where N ranges between,
    //     N = 0.50 (default)
    //     N = 0.33 (sharper)
    // {x___} = -N/screenWidthInPixels  
    // {_y__} = -N/screenHeightInPixels
    // {__z_} =  N/screenWidthInPixels  
    // {___w} =  N/screenHeightInPixels 
    FxaaFloat4 fxaaConsoleRcpFrameOpt,
    //
    // Only used on FXAA Console.
    // Not used on 360, but used on PS3 and PC.
    // This must be from a constant/uniform.
    // {x___} = -2.0/screenWidthInPixels  
    // {_y__} = -2.0/screenHeightInPixels
    // {__z_} =  2.0/screenWidthInPixels  
    // {___w} =  2.0/screenHeightInPixels 
    FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    // 
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_SHARPNESS define.
    // It is here now to allow easier tuning.
    // This does not effect PS3, as this needs to be compiled in.
    //   Use FXAA_CONSOLE__PS3_EDGE_SHARPNESS for PS3.
    //   Due to the PS3 being ALU bound,
    //   there are only three safe values here: 2 and 4 and 8.
    //   These options use the shaders ability to a free *|/ by 2|4|8.
    // For all other platforms can be a non-power of two.
    //   8.0 is sharper (default!!!)
    //   4.0 is softer
    //   2.0 is really soft (good only for vector graphics inputs)
    FxaaFloat fxaaConsoleEdgeSharpness,
    //
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD define.
    // It is here now to allow easier tuning.
    // This does not effect PS3, as this needs to be compiled in.
    //   Use FXAA_CONSOLE__PS3_EDGE_THRESHOLD for PS3.
    //   Due to the PS3 being ALU bound,
    //   there are only two safe values here: 1/4 and 1/8.
    //   These options use the shaders ability to a free *|/ by 2|4|8.
    // The console setting has a different mapping than the quality setting.
    // Other platforms can use other values.
    //   0.125 leaves less aliasing, but is softer (default!!!)
    //   0.25 leaves more aliasing, and is sharper
    FxaaFloat fxaaConsoleEdgeThreshold,
    //
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD_MIN define.
    // It is here now to allow easier tuning.
    // Trims the algorithm from processing darks.
    // The console setting has a different mapping than the quality setting.
    // This does not apply to PS3, 
    // PS3 was simplified to avoid more shader instructions.
    //   0.06 - faster but more aliasing in darks
    //   0.05 - default
    //   0.04 - slower and less aliasing in darks
    // Special notes when using FXAA_GREEN_AS_LUMA,
    //   Likely want to set this to zero.
    //   As colors that are mostly not-green
    //   will appear very dark in the green channel!
    //   Tune by looking at mostly non-green content,
    //   then start at zero and increase until aliasing is a problem.
    FxaaFloat fxaaConsoleEdgeThresholdMin
) {
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaNw = FxaaLuma(FxaaTexTop(tex, fxaaConsolePosPos.xy));
    FxaaFloat lumaSw = FxaaLuma(FxaaTexTop(tex, fxaaConsolePosPos.xw));
    FxaaFloat lumaNe = FxaaLuma(FxaaTexTop(tex, fxaaConsolePosPos.zy));
    FxaaFloat lumaSe = FxaaLuma(FxaaTexTop(tex, fxaaConsolePosPos.zw));
/*--------------------------------------------------------------------------*/
    FxaaFloat4 rgbyM = FxaaTexTop(tex, pos.xy);
    #if (FXAA_GREEN_AS_LUMA == 0)
	    // TODO Luma
        FxaaFloat lumaM = FxaaLuma(rgbyM);
    #else
        FxaaFloat lumaM = rgbyM.y;
    #endif
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaMaxNwSw = max(lumaNw, lumaSw);
    lumaNe += 1.0/384.0;
    FxaaFloat lumaMinNwSw = min(lumaNw, lumaSw);
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaMaxNeSe = max(lumaNe, lumaSe);
    FxaaFloat lumaMinNeSe = min(lumaNe, lumaSe);
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaMax = max(lumaMaxNeSe, lumaMaxNwSw);
    FxaaFloat lumaMin = min(lumaMinNeSe, lumaMinNwSw);
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaMaxScaled = lumaMax * fxaaConsoleEdgeThreshold;
/*--------------------------------------------------------------------------*/
    FxaaFloat lumaMinM = min(lumaMin, lumaM);
    FxaaFloat lumaMaxScaledClamped = max(fxaaConsoleEdgeThresholdMin, lumaMaxScaled);
    FxaaFloat lumaMaxM = max(lumaMax, lumaM);
    FxaaFloat dirSwMinusNe = lumaSw - lumaNe;
    FxaaFloat lumaMaxSubMinM = lumaMaxM - lumaMinM;
    FxaaFloat dirSeMinusNw = lumaSe - lumaNw;
    if(lumaMaxSubMinM < lumaMaxScaledClamped) 
    {
      #if (FXAA_DISCARD == 1)
        FxaaDiscard;
      #else
        return rgbyM;
      #endif
    }
/*--------------------------------------------------------------------------*/
    FxaaFloat2 dir;
    dir.x = dirSwMinusNe + dirSeMinusNw;
    dir.y = dirSwMinusNe - dirSeMinusNw;
/*--------------------------------------------------------------------------*/
    FxaaFloat2 dir1 = normalize(dir.xy);
    FxaaFloat4 rgbyN1 = FxaaTexTop(tex, pos.xy - dir1 * fxaaConsoleRcpFrameOpt.zw);
    FxaaFloat4 rgbyP1 = FxaaTexTop(tex, pos.xy + dir1 * fxaaConsoleRcpFrameOpt.zw);
/*--------------------------------------------------------------------------*/
    FxaaFloat dirAbsMinTimesC = min(abs(dir1.x), abs(dir1.y)) * fxaaConsoleEdgeSharpness;
    FxaaFloat2 dir2 = clamp(dir1.xy / dirAbsMinTimesC, -2.0, 2.0);
/*--------------------------------------------------------------------------*/
    FxaaFloat2 dir2x = dir2 * fxaaConsoleRcpFrameOpt2.zw;
    FxaaFloat4 rgbyN2 = FxaaTexTop(tex, pos.xy - dir2x);
    FxaaFloat4 rgbyP2 = FxaaTexTop(tex, pos.xy + dir2x);
/*--------------------------------------------------------------------------*/
    FxaaFloat4 rgbyA = rgbyN1 + rgbyP1;
    FxaaFloat4 rgbyB = ((rgbyN2 + rgbyP2) * 0.25) + (rgbyA * 0.25);
/*--------------------------------------------------------------------------*/
    #if (FXAA_GREEN_AS_LUMA == 0)
      // TODO Luma
      float lumaB = FxaaLuma(rgbyB);
    #else
      float lumaB = rgbyB.y;
    #endif
    if((lumaB < lumaMin) || (lumaB > lumaMax)) 
      rgbyB.xyz = rgbyA.xyz * 0.5;
    //
    return rgbyB; 
}
/*==========================================================================*/

#define edgeSharpness 3.0
#define edgeThreshold 0.15
#define edgeThresholdMin 0.05

void main(){
	vec2 screenSize05 = 0.5 * u_screenSize2f;

	vec4 posPos;
	posPos.xy = v_position2f;
	posPos.zw = v_position2f + u_screenSize2f;

	vec4 rcpFrameOpt;
	rcpFrameOpt.xy = -screenSize05;
	rcpFrameOpt.zw = screenSize05;

	EAGLER_FRAG_COLOR = vec4(FxaaPixelShader(v_position2f + screenSize05, posPos, u_screenTexture, rcpFrameOpt, rcpFrameOpt * 4.0, edgeSharpness, edgeThreshold, edgeThresholdMin).rgb, 1.0);
}
#else

// This 'optimized' code was generated using glslangValidator + spirv-cross + spirv-opt on the source code above
// Is it faster? Idfk, probably compiles faster at least, what matters it I tried

float _616;

void main()
{
    mediump vec2 _257 = u_screenSize2f * 0.5;
    mediump vec4 _611 = vec4(v_position2f, v_position2f + u_screenSize2f);
    mediump vec4 _612 = vec4(_616, _616, _257);
    mediump vec2 _290 = v_position2f + _257;
    mediump vec4 _608;
    for(;;)
    {
        mediump vec3 _532 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, _611.xy, 0.0).xyz;
        mediump float _536 = dot(_532 * _532, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
        mediump vec3 _540 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, _611.xw, 0.0).xyz;
        mediump float _544 = dot(_540 * _540, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
        mediump vec3 _548 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, _611.zy, 0.0).xyz;
        mediump vec3 _556 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, _611.zw, 0.0).xyz;
        mediump float _560 = dot(_556 * _556, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
        mediump vec4 _390 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, _290, 0.0);
        mediump vec3 _564 = _390.xyz;
        mediump float _568 = dot(_564 * _564, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
        mediump float _397 = dot(_548 * _548, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625)) + 0.00260416674427688121795654296875;
        mediump float _409 = max(max(_397, _560), max(_536, _544));
        mediump float _412 = min(min(_397, _560), min(_536, _544));
        mediump float _427 = _544 - _397;
        mediump float _433 = _560 - _536;
        if ((max(_409, _568) - min(_412, _568)) < max(0.0500000007450580596923828125, _409 * 0.1500000059604644775390625))
        {
            _608 = _390;
            break;
        }
        mediump vec2 _449 = normalize(vec2(_427 + _433, _427 - _433));
        vec2 hp_copy_449 = _449;
        mediump vec2 _454 = _612.zw;
        vec2 _614 = -hp_copy_449;
        mediump vec2 mp_copy_614 = _614;
        mediump vec2 _481 = clamp(_449 / vec2(min(abs(_449.x), abs(_449.y)) * 3.0), vec2(-2.0), vec2(2.0));
        vec2 hp_copy_481 = _481;
        mediump vec2 _484 = (_612 * 4.0).zw;
        vec2 _615 = -hp_copy_481;
        mediump vec2 mp_copy_615 = _615;
        mediump vec4 _498 = EAGLER_TEXTURE_2D_LOD(u_screenTexture, mp_copy_614 * _454 + _290, 0.0) + EAGLER_TEXTURE_2D_LOD(u_screenTexture, _449 * _454 + _290, 0.0);
        mediump vec4 _505 = ((EAGLER_TEXTURE_2D_LOD(u_screenTexture, mp_copy_615 * _484 + _290, 0.0) + EAGLER_TEXTURE_2D_LOD(u_screenTexture, _481 * _484 + _290, 0.0)) * 0.25) + (_498 * 0.25);
        mediump float _576 = dot(_505.xyz * _505.xyz, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
        mediump vec4 _607;
        if ((_576 < _412) || (_576 > _409))
        {
            mediump vec3 _518 = _498.xyz * 0.5;
            mediump vec4 _600;
            _600.x = _518.x;
            _600.y = _518.y;
            _600.z = _518.z;
            _607 = _600;
        }
        else
        {
            _607 = _505;
        }
        _608 = _607;
        break;
    }
    EAGLER_FRAG_COLOR = vec4(_608.xyz, 1.0);
}

#endif