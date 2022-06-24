uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;
uniform mat4 u_Color;
varying vec2 v_TexCoord2;

void main()
{
  vec4 col = texture2D(u_Tex0, v_TexCoord);
  float d = u_Time * 2.0;
  col.x += (1.0 + sin(d)) * 0.25;
  col.y += (1.0 + sin(d * 2.0)) * 0.25;
  col.z += (1.0 + sin(d * 4.0)) * 0.25;
  //gl_FragColor = col;

    gl_FragColor = texture2D(u_Tex0, v_TexCoord);
    vec4 texcolor = texture2D(u_Tex0, v_TexCoord2);
    if(texcolor.r > 0.9) {
        gl_FragColor *= texcolor.g > 0.9 ? u_Color[0] : u_Color[1];
    } else if(texcolor.g > 0.9) {
        gl_FragColor *= u_Color[2];
    } else if(texcolor.b > 0.9) {
        gl_FragColor *= u_Color[3];
    }
    if(texcolor.a < 0.01){
        gl_FragColor *= col*(1+sin(d));
    }


}
