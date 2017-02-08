//fragment shader
//simply displays an image

precision lowp float;

uniform sampler2D inputImageTexture;

uniform mediump mat3 convolutionMatrix;

varying highp vec2 outputTextureCoordinate;

varying highp vec2 upperLeftInputTextureCoordinate;
varying highp vec2 upperRightInputTextureCoordinate;
varying highp vec2 lowerLeftInputTextureCoordinate;
varying highp vec2 lowerRightInputTextureCoordinate;

void main()
{
    float upperLeftIntensity = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
    float upperRightIntensity = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
    float lowerLeftIntensity = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
    float lowerRightIntensity = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
    
    gl_FragColor = vec4(upperLeftIntensity, upperRightIntensity, lowerLeftIntensity, lowerRightIntensity);
}