// written by groverbuger for g3d
// september 2021
// MIT license

uniform sampler2D MainTexture;
varying vec2 UV;

// lights
varying vec3 fragPosition;
varying vec3 fragNormal;

uniform vec3 lightPosition;
uniform vec3 lightDirection;
uniform vec3 lightColor;
uniform float lightIntensity;
varying vec4 vertexColor;

// this vertex shader is what projects 3d vertices in models onto your 2d screen

#ifdef VERTEX
uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn
uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute vec3 VertexNormal;

// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;

vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
    worldPosition = modelMatrix * vertexPosition;
    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;

    // save some data from this vertex for use in fragment shaders
    vertexNormal = VertexNormal;
    vertexColor = VertexColor;

    fragPosition = vec3(worldPosition);
    fragNormal = normalize(mat3(modelMatrix) * VertexNormal);

    // for some reason models are flipped vertically when rendering to a canvas
    // so we need to detect when this is being rendered to a canvas, and flip it back
    if (isCanvasEnabled) {
        screenPosition.y *= -1.0;
    }

    return screenPosition;
}
#endif
#ifdef PIXEL
void pixel() {
    vec4 textureColor = Texel(MainTexture, UV);
    vec3 normal = normalize(fragNormal);
    vec3 lightDir = normalize(lightPosition - fragPosition);
    
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor * lightIntensity;
    
    vec3 ambient = 0.1 * lightColor;
    
    vec3 result = (ambient + diffuse) * textureColor.rgb;
    
    love_Canvases[0] = vec4(result, textureColor.a) * vertexColor;
}
#endif