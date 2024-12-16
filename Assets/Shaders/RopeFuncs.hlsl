#ifndef ROPE_FUNCS
#define ROPE_FUNCS
// Check isnan(value) before use.
inline uint OrderPreservingFloatMap(float value)
{
    // For negative values, the mask becomes 0xffffffff.
    // For positive values, the mask becomes 0x80000000.
    uint uvalue = asuint(value);
    uint mask = -int(uvalue >> 31) | 0x80000000;
    return uvalue ^ mask;
}

inline float InverseOrderPreservingFloatMap(uint value)
{
    // If the msb is set, the mask becomes 0x80000000.
    // If the msb is unset, the mask becomes 0xffffffff.
    uint mask = ((value >> 31) - 1) | 0x80000000;
    return asfloat(value ^ mask);
}

inline uint3 Float3ToUint3(float3 value)
{
    return uint3(OrderPreservingFloatMap(value.x),OrderPreservingFloatMap(value.y), OrderPreservingFloatMap(value.z));
}

inline float3 Uint3ToFloat3(uint3 value)
{
    return float3(InverseOrderPreservingFloatMap(value.x), InverseOrderPreservingFloatMap(value.y), InverseOrderPreservingFloatMap(value.z));
}

inline void WriteToBuffer(RWStructuredBuffer<uint> buffer, uint index, uint3 inPosition) {
    uint x,y,z,w = 0;
    InterlockedExchange(buffer[index*4], inPosition.x, x);
    InterlockedExchange(buffer[index*4+1], inPosition.y, y);
    InterlockedExchange(buffer[index*4+2], inPosition.z, z);
}


void WriteInitialPositions(inout VFXAttributes attributes, RWStructuredBuffer<uint> buffer, uint index) {        
    WriteToBuffer(buffer, index, attributes.position.xyz);
    attributes.oldPosition = attributes.position;
}

inline uint3 ReadBuffer(RWStructuredBuffer<uint> buffer, uint index) {
    uint x,y,z = 0;
    InterlockedAdd(buffer[index * 4], 0, x);
    InterlockedAdd(buffer[index * 4 + 1], 0, y);
    InterlockedAdd(buffer[index * 4 + 2], 0, z);
    return uint3(x,y,z);
}


void ReadPosition(inout VFXAttributes attributes, RWStructuredBuffer<uint> buffer, uint index) {
    attributes.position = Uint3ToFloat3(ReadBuffer(buffer, index));
}

void SetInitialLock(inout VFXAttributes attributes, RWStructuredBuffer<uint> buffer, uint currIndex)
{
    uint ignored = 0;    
    InterlockedExchange(buffer[currIndex * 4 + 3], currIndex, ignored);
}

void UpdateRopeConstraints(inout VFXAttributes attributes, RWStructuredBuffer<uint> buffer, float targetDist, uint bufferSize, uint currIndex, float deltaTime)
{
    float timeStep = deltaTime / 4.0;
    timeStep *= timeStep;
    uint mutex = 0;
    uint ignored = 0;

    [loop]
    for (uint k = 0; k < 4; ++k)
    {
        [loop]
        for (uint j = 0; j < 100; ++j)
        {
            InterlockedAdd(buffer[currIndex * 4 + 3], 0, mutex);
            if (mutex == currIndex)
            {
                float3 current = k == 0 ? attributes.position : Uint3ToFloat3(ReadBuffer(buffer, currIndex));
                attributes.position = current;
                if (currIndex > 0) 
                {
                    attributes.position = 2.0 * current - attributes.oldPosition + (timeStep * attributes.acceleration);
                    attributes.oldPosition = current;
                }
                WriteToBuffer(buffer, currIndex, Float3ToUint3(attributes.position));
                if (currIndex % 2 == 0)
                {
                    if(currIndex + 1 < bufferSize) 
                    {
                        InterlockedExchange(buffer[currIndex * 4 + 3], currIndex + 1, ignored);
                    }
                    else
                    {
                        InterlockedExchange(buffer[currIndex * 4 + 3], currIndex - 1, ignored);
                    }
                }                
                break;
            }
        }
        [branch]
        if (currIndex % 2 == 1)
        {
            for (uint i = 0; i < 8; ++i)
            {
                [loop]
                for (uint j = 0; j < 100; ++j)
                {
                    InterlockedAdd(buffer[(currIndex - 1) * 4 + 3], 0, mutex);
                    if (mutex == currIndex)
                    {
                        float3 current = Uint3ToFloat3(ReadBuffer(buffer, currIndex));
                        float3 other = Uint3ToFloat3(ReadBuffer(buffer, currIndex - 1));
                        float3 delta = (other - current);
                        float dist = length(delta);
                        float halfDist = (dist - targetDist) / 2.0;
                        delta = SafeNormalize(delta);
                        if (currIndex == bufferSize - 1)
                        {
                            WriteToBuffer(buffer, currIndex, Float3ToUint3(current + ((halfDist + halfDist) * delta)));
                        }
                        else
                        {
                            WriteToBuffer(buffer, currIndex, Float3ToUint3(current + (halfDist * delta)));
                            if (currIndex - 1 != 0)
                            {
                                WriteToBuffer(buffer, currIndex - 1, Float3ToUint3(other - (halfDist * delta)));
                            }
                        }
                    
                        if (currIndex >= 2)
                        {
                            InterlockedExchange(buffer[(currIndex - 1) * 4 + 3], currIndex - 2, ignored);
                        }
                        break;
                    }
                }
            
                [branch]
                if (currIndex + 1 < bufferSize)
                {
                    [loop]
                    for (uint j = 0; j < 100; ++j)
                    {
                        InterlockedAdd(buffer[(currIndex + 1) * 4 + 3], 0, mutex);
                        if (mutex == currIndex)
                        {
                            float3 current = Uint3ToFloat3(ReadBuffer(buffer, currIndex));
                            float3 other = Uint3ToFloat3(ReadBuffer(buffer, currIndex + 1));
                            float3 delta = (other - current);
                            float dist = length(delta);
                            float halfDist = (dist - targetDist) / 2.0;
                            delta = SafeNormalize(delta);
                    
                            WriteToBuffer(buffer, currIndex, Float3ToUint3(current + (halfDist * delta)));
                            WriteToBuffer(buffer, currIndex + 1, Float3ToUint3(other - (halfDist * delta)));
                            if (currIndex + 1 < bufferSize)
                            {
                                if(i == 7 || currIndex + 2 >= bufferSize) 
                                {
                                    InterlockedExchange(buffer[(currIndex + 1) * 4 + 3], currIndex + 1, ignored);
                                }
                                else 
                                {
                                    InterlockedExchange(buffer[(currIndex + 1) * 4 + 3], currIndex + 2, ignored);
                                }
                                
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    [loop]
    for (uint j = 0; j < 100; ++j)
    {
        InterlockedAdd(buffer[currIndex * 4 + 3], 0, mutex);
        if (mutex == currIndex)
        {   
            attributes.position = Uint3ToFloat3(ReadBuffer(buffer, currIndex));
            break;
        }
    }
    
}
#endif