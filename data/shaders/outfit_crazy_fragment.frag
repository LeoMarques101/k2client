uniform mat4 u_Color;
varying vec2 v_TexCoord;
varying vec2 v_TexCoord2;
uniform sampler2D u_Tex0;

uniform float u_Time;

void main()
{

    vec4 color0 = vec4(0,0,0,1);
    vec4 color1 = vec4(0,0,0,1);
    vec4 color2 = vec4(0,0,0,1);
    vec4 color3 = vec4(0,0,0,1);

    float pct = abs(sin(u_Time));

    color0 = mix(u_Color[0], u_Color[1], pct);
    color1 = mix(u_Color[1], u_Color[2], pct);
    color2 = mix(u_Color[2], u_Color[3], pct);
    color3 = mix(u_Color[3], u_Color[0], pct);

    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    if(texcolor.r > 0.9) {
        gl_FragColor *= texcolor.g > 0.9 ? color0 : color1;
    } else if(texcolor.g > 0.9) {
        gl_FragColor *= color2;
    } else if(texcolor.b > 0.9) {
        gl_FragColor *= color3;
    }
    if(gl_FragColor.a < 0.01) discard;

}

