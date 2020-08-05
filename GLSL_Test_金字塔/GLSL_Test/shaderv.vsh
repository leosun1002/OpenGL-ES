attribute vec4 position;
attribute vec4 postionColor;
attribute vec2 textCoordinate;

uniform mat4 projectionMatrix;
uniform mat4 modelviewMatrix;

varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;

void main()
{
    varyColor = postionColor;
    varyTextCoord = textCoordinate;
    
    vec4 vPos;
    vPos = projectionMatrix * modelviewMatrix * position;
    
    gl_Position = vPos;
}
