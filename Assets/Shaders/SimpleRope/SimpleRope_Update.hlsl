#ifndef SIMPLE_ROPE_UPDATE
#define SIMPLE_ROPE_UPDATE
#include "../Shared.hlsl"
void UpdateSimpleRope(inout VFXAttributes attributes, RWStructuredBuffer<int> positionsBuffer, float targetDist, float deltaTime, float constraintWeight, float pinWeight)
{    
    float timeStep = deltaTime / 8.0;
    timeStep *= timeStep;
    float vertletWeight = 1 - pinWeight;
    timeStep *= vertletWeight;
    targetDist *= vertletWeight;
    constraintWeight *= vertletWeight;
    float3 prevPosition = attributes.oldPosition;
    uint particleCountInStrip = attributes.particleCountInStrip;
    uint currIndex = attributes.stripIndex * particleCountInStrip + attributes.particleIndexInStrip;    
    for (uint k = 0; k < 8; ++k)
    {
        float3 prev = attributes.position.xyz;
        attributes.position = Int3ToFloat3(AddToBuffer(positionsBuffer, currIndex, Float3ToInt3(vertletWeight * (attributes.position - prevPosition + (timeStep * attributes.acceleration)))));
        prevPosition = prev;                
        for (uint i = 0; i < 16; ++i)
        {              
                if (attributes.particleIndexInStrip > 0) 
                {
                    uint otherIndex = currIndex - 1;
                    float3 other = Int3ToFloat3(AtomicReadBuffer(positionsBuffer, otherIndex));
                    float3 delta = other - attributes.position;
                    float dist = length(delta);
                    float scaledDist = (dist - targetDist) * constraintWeight;               
                    delta = SafeNormalize(delta);                                        
                    attributes.position = Int3ToFloat3(AddToBuffer(positionsBuffer, currIndex, Float3ToInt3((scaledDist  * delta))));
                }                
                if (attributes.particleIndexInStrip + 1 < attributes.particleCountInStrip)
                {
                    uint otherIndex = currIndex + 1;
                    float3 other = Int3ToFloat3(AtomicReadBuffer(positionsBuffer, otherIndex));
                    float3 delta = other - attributes.position;
                    float dist = length(delta);
                    float scaledDist = (dist - targetDist) * constraintWeight;                    
                    delta = SafeNormalize(delta);                    
                    attributes.position = Int3ToFloat3(AddToBuffer(positionsBuffer, currIndex, Float3ToInt3((scaledDist  * delta))));
                }
                
        }
    }    
}

#endif