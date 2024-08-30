    #version 150 compatibility
    #line 100002
    //VertexShader
    // Set the precision for data types used in this shader

    //declare uniforms
    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normaltex;
    uniform sampler2D reflecttex;
    uniform sampler2D screentex;
    uniform sampler2D afterglowbuffertex;
    
    uniform float time;
    uniform float timepercent;
    uniform vec2 viewPortSize;
    uniform int typeDefID;

   const float PI = 3.1415926535897932384626433832795;

    // Variables passed from vertex to fragment shader
    out Data {      
            vec3 vPixelPositionWorld;
            vec3 normal;
            vec3 sphericalNormal;
            vec2 orgColUv;
        };


void main() 
{

    normal = gl_NormalMatrix * gl_Normal;
    orgColUv = gl_MultiTexCoord0.xy;

	//Calculate the world Vertex Position ? Operation Order wrong?
    vec4 worldVertPos = gl_ModelViewMatrixInverseTranspose * (gl_ModelViewMatrix * gl_Vertex);
    
    vec3 posCopy = gl_Vertex.xyz;
	gl_Position = gl_ModelViewProjectionMatrix * vec4(posCopy.x, posCopy.y, posCopy.z, 1.0);
    vPixelPositionWorld = gl_Position.xyz;

}