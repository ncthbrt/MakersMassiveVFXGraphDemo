#ifndef ROPE_FUNCS
#define ROPE_FUNCS

inline int OrderPreservingFloatMap(float value)
{  
    return (int)(value * (1<<16));
}

inline float InverseOrderPreservingFloatMap(int value)
{    
    return ((float)value) / (1<<16);
}

inline int3 Float3ToInt3(float3 value)
{
    return int3(OrderPreservingFloatMap(value.x), OrderPreservingFloatMap(value.y), OrderPreservingFloatMap(value.z));
}

inline float3 Int3ToFloat3(int3 value)
{
    return float3(InverseOrderPreservingFloatMap(value.x), InverseOrderPreservingFloatMap(value.y), InverseOrderPreservingFloatMap(value.z));
}

inline void WriteToBuffer(RWStructuredBuffer<int> buffer, uint index, int3 inPosition) {
    int x,y,z = 0;
    InterlockedExchange(buffer[index*4], inPosition.x, x);
    InterlockedExchange(buffer[index*4+1], inPosition.y, y);
    InterlockedExchange(buffer[index*4+2], inPosition.z, z);
}

inline int3 AddToBuffer(RWStructuredBuffer<int> buffer, uint index, int3 delta) {
    int x,y,z = 0;
    
    InterlockedAdd(buffer[index*4], delta.x, x);
    InterlockedAdd(buffer[index*4+1], delta.y, y);
    InterlockedAdd(buffer[index*4+2], delta.z, z);
    return int3(x,y,z) + delta;
}


void WritePositions(inout VFXAttributes attributes, RWStructuredBuffer<int> buffer, uint index) {        
    WriteToBuffer(buffer, index, Float3ToInt3(attributes.position));
    attributes.oldPosition = attributes.position;
}

inline int3 ReadBuffer(RWStructuredBuffer<int> buffer, uint index) {
    int x,y,z = 0;
    InterlockedAdd(buffer[index * 4], 0, x);
    InterlockedAdd(buffer[index * 4 + 1], 0, y);
    InterlockedAdd(buffer[index * 4 + 2], 0, z);
    return int3(x,y,z);
}


void UpdateRopeConstraints(inout VFXAttributes attributes, RWStructuredBuffer<int> buffer, float targetDist, uint bufferSize, uint currIndex, float deltaTime, float stiffness)
{
    float timeStep = deltaTime / 8.0;
    timeStep *= timeStep;
    int vertletWeight = (int) saturate(currIndex);
    timeStep *= vertletWeight;
    targetDist *= vertletWeight;
    stiffness *= vertletWeight;
    float3 prevPosition = attributes.oldPosition;    
    [unroll]
    for (uint k = 0; k < 8; ++k)
    {
        float3 prev = attributes.position.xyz;
        attributes.position = Int3ToFloat3(AddToBuffer(buffer, currIndex, Float3ToInt3(vertletWeight * (attributes.position - prevPosition + (timeStep * attributes.acceleration)))));
        prevPosition = prev;
        [loop]
        for (uint i = 0; i < 16; ++i)
        {
            for (int j = -1; j<=1; j+=2)
            {
                uint index = min(bufferSize - 1, (uint) ((int)currIndex + j));
                float3 other = Int3ToFloat3(ReadBuffer(buffer, index));
                float3 delta = other - attributes.position;
                float dist = length(delta);
                float scaledDist = (dist - targetDist) * stiffness;
                delta = SafeNormalize(delta);
                attributes.position = Int3ToFloat3(AddToBuffer(buffer, currIndex, Float3ToInt3((scaledDist  * delta))));
            }
        }
    }
} 

#endif