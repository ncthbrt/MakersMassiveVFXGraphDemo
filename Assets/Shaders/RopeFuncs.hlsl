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


void WritePositions(inout VFXAttributes attributes, RWStructuredBuffer<int> buffer) {        
    uint index = attributes.stripIndex * attributes.particleCountInStrip + attributes.particleIndexInStrip;
    WriteToBuffer(buffer, index, Float3ToInt3(attributes.position));
}

inline int3 AtomicReadBuffer(RWStructuredBuffer<int> buffer, uint index) {
    int x,y,z = 0;
    InterlockedAdd(buffer[index * 4], 0, x);
    InterlockedAdd(buffer[index * 4 + 1], 0, y);
    InterlockedAdd(buffer[index * 4 + 2], 0, z);
    return int3(x,y,z);
}

inline int3 ReadBuffer(RWStructuredBuffer<int> buffer, uint index) 
{
    return int3(buffer[index * 4], buffer[index * 4 + 1], buffer[index * 4 + 2]);
}


void SamplePosition(RWStructuredBuffer<int> buffer, uint particleCountPerStrip, uint stripIndex, uint particleIndexInStrip, out float3 position) 
{
    uint index = stripIndex * particleCountPerStrip + particleIndexInStrip;
    position = Int3ToFloat3(ReadBuffer(buffer, index));
}


void UpdateRopeConstraints(inout VFXAttributes attributes, RWStructuredBuffer<int> buffer, float targetDist, float deltaTime, float stiffness, float pinWeight)
{
    float timeStep = deltaTime / 8.0;
    timeStep *= timeStep;
    float vertletWeight = 1 - pinWeight;
    timeStep *= vertletWeight;
    targetDist *= vertletWeight;
    stiffness *= vertletWeight;
    float3 prevPosition = attributes.oldPosition;
    uint currIndex = attributes.stripIndex * attributes.particleCountInStrip + attributes.particleIndexInStrip;
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
                uint otherIndex = attributes.stripIndex * attributes.particleCountInStrip + min(attributes.particleCountInStrip - 1, (uint) ((int)attributes.particleIndexInStrip + j));
                if(otherIndex != currIndex)
                {
                    float3 other = Int3ToFloat3(AtomicReadBuffer(buffer, otherIndex));
                    float3 delta = other - attributes.position;
                    float dist = length(delta);
                    float scaledDist = (dist - targetDist) * stiffness;
                    delta = SafeNormalize(delta);
                    attributes.position = Int3ToFloat3(AddToBuffer(buffer, currIndex, Float3ToInt3((scaledDist  * delta))));
                }
            }
        }
    }
} 

#endif