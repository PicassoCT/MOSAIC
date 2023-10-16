    #version 150 compatibility
    //VertexShader
    // Set the precision for data types used in this shader


    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normalTex;
    uniform sampler2D reflectTex;
    uniform sampler2D screenTex;
    uniform sampler2D depthTex;
    
    uniform mat4 modelMatrix;
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;
    uniform mat4 viewInvMat;

    uniform float viewPosX;
    uniform float viewPosY;

    // Default uniforms provided by ShaderFrog.
    uniform float time;

    // Variables passed from vertex to fragment shader
    out Data {
        vec3 vViewCameraDir;
        vec3 vPositionWorld;
        vec3 vWorldNormal;
        vec2 vTexCoord;
        };


    float shiver(float posy, float scalar, float size) {
        if (sin(posy + time) < size)
        { return 1.0;};
        
        float renormalizedTime = sin(posy +time);
        
        return scalar*((renormalizedTime-(1.0 + (size/2.0)))/ (size/2.0));
    }

    void main() 
    {
        vPositionWorld =  (  modelMatrix * vec4(gl_Vertex.xyz ,0)).xyz;
        vTexCoord.xy=  gl_MultiTexCoord0.xy;
        vWorldNormal = gl_Vertex.xyz* mat3(viewInvMat) * (gl_NormalMatrix * gl_Normal);

        vec4 worldVertPos = viewInvMat * (gl_ModelViewMatrix * gl_Vertex);
        vec4 worldCamPos = viewInvMat * vec4(0.0, 0.0, 0.0, 1.0);

        vViewCameraDir = worldCamPos.xyz - worldVertPos.xyz;

        vec3 posCopy = gl_Vertex.xyz;
    	posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
        gl_Vertex = gl_ModelViewProjectionMatrix  * gl_ModelViewMatrix * vec4(posCopy, 1.0);
    	gl_Vertex.xz = gl_Vertex.xz* ((8.0 - sin(gl_Position.y + time * (1.0 +abs(cos(time)))))/8.0);
		gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	}