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
    uniform  vec3 unitCenterPosition;

   const float PI = 3.1415926535897932384626433832795;

    // Variables passed from vertex to fragment shader
    out Data {      
            vec2 vSphericalUVs;
            vec3 vPixelPositionWorld;
            vec3 normal;
            vec3 sphericalNormal;
            vec2 orgColUv;
        };


float shiver(float posy, float scalar, float size)
{
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
    sphericalNormal = normalizedVector;
    // Step 2: Convert to spherical coordinates (longitude and latitude)
    float longitude = atan(normalizedVector.y, normalizedVector.x);
    float latitude = acos(normalizedVector.z);

    // Step 3: Map spherical coordinates to UV coordinates

    vSphericalUVs.x = (longitude + PI) / (2.0 * PI);
    vSphericalUVs.y = latitude / PI;
}

void main() 
{

    normal = gl_NormalMatrix * gl_Normal;
    orgColUv = gl_MultiTexCoord0.xy;
	//TODO Loads of dead code, no idea how this worked? 
	//Calculate the world position of the vertex
    vPixelPositionWorld =  (  gl_ModelViewMatrix * vec4(gl_Vertex.xyz ,0)).xyz;
    CreateSphericalUVs(vPixelPositionWorld);
	//Calculate the world Vertex Position ? Operation Order wrong?
    vec4 worldVertPos = gl_ModelViewMatrixInverseTranspose * (gl_ModelViewMatrix * gl_Vertex);
    
    vec3 posCopy = gl_Vertex.xyz;
    //We shiver the polygons to the side ocassionally in ripples
	posCopy.xz = posCopy.xz - 32.0 * (shiver(posCopy.y, 0.16, 0.95));
	gl_Position = gl_ModelViewProjectionMatrix * vec4(posCopy.x, posCopy.y, posCopy.z, 1.0);
}