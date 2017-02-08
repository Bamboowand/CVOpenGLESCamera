//fragment shader
//simply displays an image

uniform sampler2D inputImageTexture;

varying highp vec2 textureCoordinate;
varying highp vec2 leftTextureCoordinate;
varying highp vec2 rightTextureCoordinate;

varying highp vec2 topTextureCoordinate;
varying highp vec2 topLeftTextureCoordinate;
varying highp vec2 topRightTextureCoordinate;

varying highp vec2 bottomTextureCoordinate;
varying highp vec2 bottomLeftTextureCoordinate;
varying highp vec2 bottomRightTextureCoordinate;

uniform lowp float threshold;
uniform highp float texelWidth;
uniform highp float texelHeight;

highp float encodedIntensity(highp vec3 sourceColor)
{
    return (sourceColor.b * 256.0 * 256.0 + sourceColor.g * 256.0 + sourceColor.r);
}

void main()
{
    highp float bottomColor = encodedIntensity(texture2D(inputImageTexture, bottomTextureCoordinate).rgb);
    highp float bottomLeftColor = encodedIntensity(texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb);
    highp float bottomRightColor = encodedIntensity(texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb);
    highp float centerColor = encodedIntensity(texture2D(inputImageTexture, textureCoordinate).rgb);
    highp float leftColor = encodedIntensity(texture2D(inputImageTexture, leftTextureCoordinate).rgb);
    highp float rightColor = encodedIntensity(texture2D(inputImageTexture, rightTextureCoordinate).rgb);
    highp float topColor = encodedIntensity(texture2D(inputImageTexture, topTextureCoordinate).rgb);
    highp float topRightColor = encodedIntensity(texture2D(inputImageTexture, topRightTextureCoordinate).rgb);
    highp float topLeftColor = encodedIntensity(texture2D(inputImageTexture, topLeftTextureCoordinate).rgb);
    
    highp float secondStageColor1 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-2.0 * texelWidth, -2.0 * texelHeight)).rgb);
    highp float secondStageColor2 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-2.0 * texelWidth, -1.0 * texelHeight)).rgb);
    highp float secondStageColor3 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-2.0 * texelWidth, 0.0)).rgb);
    highp float secondStageColor4 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-2.0 * texelWidth, 1.0 * texelHeight)).rgb);
    highp float secondStageColor5 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-2.0 * texelWidth, 2.0 * texelHeight)).rgb);
    highp float secondStageColor6 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-1.0 * texelWidth, 2.0 * texelHeight)).rgb);
    highp float secondStageColor7 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(0.0, 2.0 * texelHeight)).rgb);
    highp float secondStageColor8 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(1.0 * texelWidth, 2.0 * texelHeight)).rgb);
    
    highp float thirdStageColor1 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(-1.0 * texelWidth, -2.0 * texelHeight)).rgb);
    highp float thirdStageColor2 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(0.0, -2.0 * texelHeight)).rgb);
    highp float thirdStageColor3 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(1.0 * texelWidth, -2.0 * texelHeight)).rgb);
    highp float thirdStageColor4 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(2.0 * texelWidth, -2.0 * texelHeight)).rgb);
    highp float thirdStageColor5 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(2.0 * texelWidth, -1.0 * texelHeight)).rgb);
    highp float thirdStageColor6 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(2.0 * texelWidth, 0.0)).rgb);
    highp float thirdStageColor7 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(2.0 * texelWidth, 1.0 * texelHeight)).rgb);
    highp float thirdStageColor8 = encodedIntensity(texture2D(inputImageTexture, textureCoordinate + vec2(2.0 * texelWidth, 2.0 * texelHeight)).rgb);
    
    // Use a tiebreaker for pixels to the left and immediately above this one
    highp float multiplier = 1.0 - step(centerColor, topColor);
    multiplier = multiplier * (1.0 - step(centerColor, topLeftColor));
    multiplier = multiplier * (1.0 - step(centerColor, leftColor));
    multiplier = multiplier * (1.0 - step(centerColor, bottomLeftColor));
    
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor1));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor2));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor3));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor4));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor5));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor6));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor7));
    multiplier = multiplier * (1.0 - step(centerColor, secondStageColor8));
    
    highp float maxValue = max(centerColor, bottomColor);
    maxValue = max(maxValue, bottomRightColor);
    maxValue = max(maxValue, rightColor);
    maxValue = max(maxValue, topRightColor);
    
    maxValue = max(maxValue, thirdStageColor1);
    maxValue = max(maxValue, thirdStageColor2);
    maxValue = max(maxValue, thirdStageColor3);
    maxValue = max(maxValue, thirdStageColor4);
    maxValue = max(maxValue, thirdStageColor5);
    maxValue = max(maxValue, thirdStageColor6);
    maxValue = max(maxValue, thirdStageColor7);
    maxValue = max(maxValue, thirdStageColor8);
    
    highp float midValue = centerColor * step(maxValue, centerColor) * multiplier;
    highp float finalValue = step(threshold, midValue);
    
    gl_FragColor = vec4(finalValue * centerColor, topLeftColor, topRightColor, topColor);
}