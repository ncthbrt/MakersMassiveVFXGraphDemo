#ifndef INELASTIC_PARTICLE_CONSTRAINTS
#define INELASTIC_PARTICLE_CONSTRAINTS
#include "./Shared.cginc"

void InitializeInelasticParticle(inout VFXAttributes attributes, RWStructuredBuffer<int> constraintBuffer, uint constraints) {
    uint startIndex = 0;
    InterlockedAdd(constraintBuffer[0], constraintCount, startIndex);
    attributes.constraintStart = startIndex;
    attributes.constraints = 0;
}


void AddInelasticConstraint(inout VFXAttributes attributes, RWStructuredBuffer<int> constraintBuffer, uint particleIndex, float targetDist, float weight) {    
    uint index = (attributes.constraintStart + attributes.constraints) * 3 + 1;
    attributes.constraints = attributes.constraints + 1;
    constraintBuffer[index] = particleIndex;
    constraintBuffer[index + 1] = OrderPreservingFloatMap(targetDist);
    constraintBuffer[index + 2] = OrderPreservingFloatMap(weight);
}

void UpdateInelasticConstraint(inout VFXAttributes attributes, RWStructuredBuffer<int> constraintBuffer, uint constraintIndex, uint particleIndex, float targetDist, float weight) {
    uint index = (attributes.constraintStart + constraintIndex) * 3 + 1;
    constraintBuffer[index] = particleIndex;
    constraintBuffer[index + 1] = OrderPreservingFloatMap(targetDist);
    constraintBuffer[index + 2] = OrderPreservingFloatMap(weight);
}

void UpdateInelasticParticle(inout VFXAttributes attributes, RWStructuredBuffer<int> positionBuffer, RWStructuredBuffer<int> constraintBuffer,  float deltaTime, float pinWeight)
{
    float timeStep = deltaTime / 8.0;
    timeStep *= timeStep;
    float vertletWeight = 1 - pinWeight;
    timeStep *= vertletWeight;
    float3 prevPosition = attributes.oldPosition;
    uint currIndex = attributes.particleId;
    uint constraintStart = attributes.constraintStart; 
    uint constraintEnd = constraintStart + attributes.constaints;    
    [unroll]
    for (uint k = 0; k < 8; ++k)
    {
        float3 prev = attributes.position.xyz;
        attributes.position = Int3ToFloat3(AddToBuffer(positionBuffer, currIndex, Float3ToInt3(vertletWeight * (attributes.position - prevPosition + (timeStep * attributes.acceleration)))));
        prevPosition = prev;
        [loop]
        for (uint i = 0; i < 16; ++i)
        {
            for (int j = constraintStart; j < constraintEnd; ++j)
            {
                uint otherIndex = constraintBuffer[3 * j + 1];
                float targetDist = InverseOrderPreservingFloatMap(constraintBuffer[3 * j + 2]) * vertletWeight;
                float weight = InverseOrderPreservingFloatMap(constraintBuffer[3 * vertletWeight * j + 3]) * vertletWeight;
                float3 other = Int3ToFloat3(AtomicReadBuffer(positionBuffer, otherIndex));
                float3 delta = other - attributes.position;
                float dist = length(delta);
                float scaledDist = (dist - targetDist) * weight;
                delta = SafeNormalize(delta);
                attributes.position = Int3ToFloat3(AddToBuffer(positionBuffer, currIndex, Float3ToInt3((scaledDist  * delta))));
            }
        }
    }
}

#endif