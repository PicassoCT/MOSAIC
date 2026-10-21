#version 150 compatibility
uniform vec3 cameraPosition;
uniform vec3 driftDirection;
out vec4 wakeUVTime;
out vec2 wakeParameters;
out vec3 wakeBoundary;

void main() {
    // Attributes are batched for every span; age is elapsed simulation time,
    // independent of distance along the path and of the dead projectile.
    float side=gl_MultiTexCoord0.x;
    float distanceAlong=gl_MultiTexCoord0.y;
    float age=max(0.0,gl_MultiTexCoord0.z);
    vec3 direction=gl_MultiTexCoord1.xyz;
    float width=gl_MultiTexCoord1.w;
    float seed=gl_MultiTexCoord2.x;
    vec3 helper=abs(direction.y)<0.9 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 u=normalize(cross(direction,helper));
    vec3 v=cross(direction,u);
    float loosen=1.0-exp(-age*0.45);
    float phase=distanceAlong*0.078-age*0.42+seed*0.31;
    float radius=width*(0.035+0.52*loosen);
    vec3 curl=radius*(u*(sin(phase)+0.24*sin(phase*2.17+seed))
        +v*(0.72*cos(phase*0.93+seed*0.19)));
    // A few world units of coherent movement; no ever-growing advection.
    float drift=1.0-exp(-age*0.11);
    vec3 p=gl_Vertex.xyz+curl+driftDirection*min(3.0,width*0.7)*drift
        +vec3(0,min(2.0,width*0.4)*drift,0);
    vec3 across=cross(direction,cameraPosition-p);
    if (dot(across,across)<1e-8) across=u;
    across=normalize(across);
    p+=across*side*width*(1.0+1.05*loosen);
    wakeUVTime=vec4(side,distanceAlong,gl_MultiTexCoord0.z,gl_MultiTexCoord0.w);
    wakeParameters=gl_MultiTexCoord2.xy;
    wakeBoundary=vec3(gl_Vertex.w,gl_MultiTexCoord2.zw);
    gl_Position=gl_ModelViewProjectionMatrix*vec4(p,1.0);
}
