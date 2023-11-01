    #version 150 compatibility
    //VertexShader
    // Set the precision for data types used in this shader

    //declare uniforms
    uniform sampler2D tex1;
    uniform sampler2D tex2;
    uniform sampler2D normalTex;
    uniform sampler2D reflectTex;
    uniform sampler2D screenTex;
    uniform sampler2D depthTex;
    
    uniform float time;
    uniform float viewPosX;
    uniform float viewPosY;
    uniform  float unitCenterPosition[3];

    //uniform mat4 modelMatrix;
    uniform mat4 viewMat;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;
    uniform mat4 viewInvMat;

   const float PI = 3.1415926535897932384626433832795;

    // Variables passed from vertex to fragment shader
    out Data {
            vec3 vViewCameraDir;
            vec3 vWorldNormal;
            vec2 vSphericalUVs;
            vec3 vPixelPositionWorld;
            vec2 vTexCoord;
            vec4 vCamPositionWorld;
        };


    float shiver(float posy, float scalar, float size) {
        if (sin(posy + time) < size)
        { return 1.0;};
        
        float renormalizedTime = sin(posy +time);
        
        return scalar*((renormalizedTime-(1.0 + (size/2.0)))/ (size/2.0));
    }

void CreateSphericalUVs(vec3 worldPosition)
{
    vec3 vertex =  vec3(unitCenterPosition[0],unitCenterPosition[1],unitCenterPosition[2])-worldPosition;
    // Step 1: Normalize the vector
    vec3 normalizedVector = normalize(vertex);

    // Step 2: Convert to spherical coordinates (longitude and latitude)
    float longitude = atan(normalizedVector.y, normalizedVector.x);
    float latitude = acos(normalizedVector.z);

    // Step 3: Map spherical coordinates to UV coordinates

    vSphericalUVs.x = (longitude + PI) / (2.0 * PI);
    vSphericalUVs.y = latitude / PI;
}


    void main() 
    {
		//TODO Loads of dead code, no idea how this worked? 
		//Calculate the world position of the vertex
        //vPixelPositionWorld =  (  modelMatrix * vec4(gl_Vertex.xyz ,0)).xyz;
        vPixelPositionWorld =  (  gl_ModelViewMatrix * vec4(gl_Vertex.xyz ,0)).xyz;
        CreateSphericalUVs(vPixelPositionWorld);
		//Texture coordinates are passed on to the fragment?
		vTexCoord.xy=  gl_MultiTexCoord0.xy;
		//Calculate the worldNormal used to calculate a average model self-normal-shadow?
        vWorldNormal = gl_Vertex.xyz* mat3(viewInvMat) * (gl_NormalMatrix * gl_Normal);
		//Calculate the world Vertex Position ? Operation Order wrong?
        vec4 worldVertPos = viewInvMat * (gl_ModelViewMatrix * gl_Vertex);
        //Crap, just crap
		vCamPositionWorld = viewInvMat * vec4(0.0, 0.0, 0.0, 1.0);

        vViewCameraDir = vCamPositionWorld.xyz - worldVertPos.xyz;

        vec3 posCopy = gl_Vertex.xyz;
    	posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
    	gl_Position = gl_ModelViewProjectionMatrix * vec4(posCopy.x, posCopy.y, posCopy.z, 1.0)  ;
	}