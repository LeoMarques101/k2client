uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;
uniform float u_Time;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                * 43758.5453123);
}

void main()
{
    vec2 st = gl_FragCoord.xy / v_TexCoord.xy;
    st.x *= v_TexCoord.x / v_TexCoord.y;
    float pct = abs(sin(u_Time));
    float r = random(st * pct);


    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    if(texcolor.r > 0.9) {
        gl_FragColor *= texcolor.g > 0.9 ? vec4(vec3(r), 1.0) : vec4(vec3(r), 1.0);
    } else if(texcolor.g > 0.9) {
        gl_FragColor *= vec4(vec3(r), 1.0);
    } else if(texcolor.b > 0.9) {
        gl_FragColor *= vec4(vec3(r), 1.0);
    }
    if(gl_FragColor.a < 0.01) discard;

}
