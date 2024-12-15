#ifndef ROPE_FUNCS
#define ROPE_FUNCS
// Check isnan(value) before use.
uint OrderPreservingFloatMap(float value)
{
    // For negative values, the mask becomes 0xffffffff.
    // For positive values, the mask becomes 0x80000000.
    uint uvalue = asuint(value);
    uint mask = -int(uvalue >> 31) | 0x80000000;
    return uvalue ^ mask;
}

float InverseOrderPreservingFloatMap(uint value)
{
    // If the msb is set, the mask becomes 0x80000000.
    // If the msb is unset, the mask becomes 0xffffffff.
    uint mask = ((value >> 31) - 1) | 0x80000000;
    return asfloat(value ^ mask);
}

void AtomicWriteBuffer(RWStructuredBuffer<uint3> positions, uint index, float3 inPosition) {
    uint3 _ignored = uint3(0, 0, 0);
    InterlockedExchange(positions[index].x, OrderPreservingFloatMap(inPosition.x), _ignored.x);
    InterlockedExchange(positions[index].y, OrderPreservingFloatMap(inPosition.y), _ignored.y);
    InterlockedExchange(positions[index].z, OrderPreservingFloatMap(inPosition.z), _ignored.z);
}

void WriteBuffer(VFXAttributes attributes, RWStructuredBuffer<uint3> positions, uint index) {    
	AtomicWriteBuffer(positions, index, attributes.position);
}

void AtomicLoadBuffer(RWStructuredBuffer<uint3> positions, uint index, out float3 outPosition) {
    uint3 position = uint3(0, 0, 0);
    InterlockedAdd(positions[index].x, 0, position.x);
    InterlockedAdd(positions[index].y, 0, position.y);
    InterlockedAdd(positions[index].z, 0, position.z);
    outPosition = float3(InverseOrderPreservingFloatMap(position.x), InverseOrderPreservingFloatMap(position.y), InverseOrderPreservingFloatMap(position.z));    
}

void UpdateRope(inout VFXAttributes attributes, RWStructuredBuffer<uint3> positions, RWStructuredBuffer<uint> mutexes, float targetDist, uint bufferSize, uint currIndex)
{   
    uint ignored = 0;
    uint mutex = 0;
    AtomicWriteBuffer(positions, currIndex, attributes.position);
    InterlockedExchange(mutexes[currIndex], currIndex + 1, ignored);

    for (uint i = 0; i < 48; ++i)
    {   
        if (currIndex > 0) 
        {
            for(uint j=0; j<10; ++j)
            {
                InterlockedAdd(mutexes[currIndex - 1], 0, mutex);
                if(mutex == currIndex)
                {
                    float3 current = float3(0.0, 0.0, 0.0);
                    float3 other = float3(0.0, 0.0, 0.0);
                    AtomicLoadBuffer(positions, currIndex, current);
                    // AtomicLoadBuffer(positions, currIndex - 1, other);
                    
                    // float3 delta = (current - other);
                    // float dist = length(delta);
                    // float halfDist = (dist - targetDist) / 2.0;
                    // delta = SafeNormalize(delta);
                    // if (currIndex == bufferSize - 1)
                    // {
                    //     AtomicWriteBuffer(positions, currIndex, current + ((halfDist + halfDist) * delta));
                    // }
                    // else
                    // {
                    //     AtomicWriteBuffer(positions, currIndex, current + (halfDist * delta));
                    //     AtomicWriteBuffer(positions, currIndex - 1, other - (halfDist * delta));
                    // }
                    
                    InterlockedExchange(mutexes[currIndex - 1], currIndex - 1, ignored);
                    break;
                }
            }
        }
        
        if (currIndex + 1 < bufferSize)
        {
            for(uint j=0; j<10; ++j) 
            {
                InterlockedAdd(mutexes[currIndex], 0, mutex);
                if(mutex == currIndex)
                {
                    // float3 current = float3(0.0, 0.0, 0.0);
                    // float3 other = float3(0.0, 0.0, 0.0);
                    // AtomicLoadBuffer(positions, currIndex, current);
                    // AtomicLoadBuffer(positions, currIndex + 1, other);                    
                    // float3 delta = (current - other);
                    // float dist = length(delta);
                    // float halfDist = (dist - targetDist) / 2.0;
                    // delta = SafeNormalize(delta);
                  
                    // AtomicWriteBuffer(positions, currIndex, current + (halfDist * delta));
                    // AtomicWriteBuffer(positions, currIndex + 1, other - (halfDist * delta));
                    // InterlockedExchange(mutexes[currIndex], currIndex + 1, ignored);
                    // break;
                }
            }
        }
    }

    AtomicLoadBuffer(positions, currIndex, attributes.position);
}
#endif