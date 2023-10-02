--VertexShader
return [[
    #version 150 compatibility
    // Set the precision for data types used in this shader
    precision highp float;
    precision highp int;


    // Default THREE.js uniforms available to both fragment and vertex shader
    uniform mat4 modelMatrix;
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;
    uniform mat3 normalMatrix;

    // Default uniforms provided by ShaderFrog.
    uniform float time;

    // Default attributes provided by THREE.js. Attributes are only available in the
    // vertex shader. You can pass them to the fragment shader using varyings
    in vec3 position;
    in vec3 normal;
    in vec2 uv;
    in vec2 uv2;

    // Examples of variables passed from vertex to fragment shader
    out vec3 vPositionWorld;
    out vec3 vNormal;
    out vec2 vUv;
    out vec2 vUv2;
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
        vNormal = normal;
        vUv = uv;
        vUv2 = uv2;
        vec4 pos =(  modelMatrix * vec4(position,0));
        vPositionWorld =  pos.xyz;
        vTexCoord.xy= position.xy;
        vNormal = normalMatrix * normal;
        vec3 posCopy = position;
    	posCopy.xz = posCopy.xz - 0.15 * (shiver(posCopy.y, 0.16, 0.95));
        gl_Position = projectionMatrix * modelViewMatrix * vec4(posCopy, 1.0);
    	//	gl_Position.xz = gl_Position.xz* ((8.0 - sin(gl_Position.y + time * (1.0 +abs(cos(time)))))/8.0);
        
        gl_Position = position;
}]]