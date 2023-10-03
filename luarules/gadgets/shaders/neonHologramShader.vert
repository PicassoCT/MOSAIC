return [[
    #version 150 compatibility
    //VertexShader
    // Set the precision for data types used in this shader
    precision highp float;
    precision highp int;

    uniform mat4 modelMatrix;
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;

    // Default uniforms provided by ShaderFrog.
    uniform float time;

    // vertex shader. You can pass them to the fragment shader using varyings
    in vec2 uv;

    // Variables passed from vertex to fragment shader
    out vec3 vPositionWorld;
    out vec3 vWorldNormal;
    out vec2 vUv;
    out vec2 vTexCoord;

    float scaleTimeFullHalf(){
        return (2.0 +sin(time))/2.0;
    }

    float shiver(float posy, float scalar, float size) {
        if (sin(posy + time) < size)
        { return 1.0;};
        
        float renormalizedTime = sin(posy +time);
        
        return scalar*((renormalizedTime-(1.0 + (size/2.0)))/ (size/2.0));
    }

    void main() {
        
        // To pass variables to the fragment shader, you assign them here in the
        // main function. Traditionally you name the varying with vAttributeName
        vUv = uv;
        vPositionWorld =  (  modelMatrix * vec4(gl_Vertex.xyz ,0)).xyz;
        vTexCoord.xy= gl_Vertex.xy;
        vWorldNormal = normalMatrix * gl_Normal;
        vec3 posCopy = gl_Vertex.xyz;
    	posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
        gl_Position = projectionMatrix * modelViewMatrix * vec4(posCopy, 1.0);
    	gl_Position.xz = gl_Position.xz* ((8.0 - sin(gl_Position.y + time * (1.0 +abs(cos(time)))))/8.0);

}]]