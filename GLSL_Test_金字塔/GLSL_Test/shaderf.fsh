precision highp float;
varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;
uniform sampler2D textCoordMap;
uniform float alpha;

void main(){
//    gl_FragColor = varyColor;
    
    vec4 textureColor = texture2D(textCoordMap,varyTextCoord);
    vec4 color = varyColor;
        
    vec4 tempColor = mix(textureColor,color,alpha);
    gl_FragColor = tempColor;
}
