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

inline void WriteToPositionsBuffer(RWStructuredBuffer<uint> positions, uint index, uint3 inPosition) {
    uint x,y,z,w = 0;
    InterlockedExchange(positions[index*4], inPosition.x, x);
    InterlockedExchange(positions[index*4+1], inPosition.y, y);
    InterlockedExchange(positions[index*4+2], inPosition.z, z);
    InterlockedExchange(positions[index*4+3], index + 1, w);
}


void WriteBuffer(VFXAttributes attributes, RWStructuredBuffer<uint> positions, uint index) {        
    WriteToPositionsBuffer(positions, index, attributes.position.xyz);
}

inline uint3 ReadPositionsBuffer(RWStructuredBuffer<uint> positions, uint index) {
    uint x,y,z = 0;
    InterlockedAdd(positions[index * 4], 0, x);
    InterlockedAdd(positions[index * 4 + 1], 0, y);
    InterlockedAdd(positions[index * 4 + 2], 0, z);
    return uint3(x,y,z);
}


void IntegrateVerlet(inout VFXAttributes attributes, RWStructuredBuffer<uint> positions, uint index, float deltaTime)
{
    attributes.position = 2.0 * Uint3ToFloat3(ReadPositionsBuffer(positions, index)) - attributes.oldPosition + ((deltaTime*deltaTime) * attributes.acceleration);    
    WriteToPositionsBuffer(positions, index, Float3ToUint3(attributes.position));
}


void ReadPosition(inout VFXAttributes attributes, RWStructuredBuffer<uint> positions, uint index) {
    attributes.position = Uint3ToFloat3(ReadPositionsBuffer(positions, index));    
}

void UpdateRopeConstraints(inout VFXAttributes attributes, RWStructuredBuffer<uint> positions, float targetDist, uint bufferSize, uint currIndex)
{
    uint ignored = 0;
    uint mutex = 0;
    WriteToPositionsBuffer(positions, currIndex, Float3ToUint3(attributes.position));
    InterlockedExchange(positions[currIndex * 4 + 3], currIndex + 1, ignored);
    
    for (uint i = 0; i < 48; ++i) {
        if (currIndex % 2 == 1) 
        { 
            for(uint j=0; j<100; ++j)
            {
                InterlockedAdd(positions[(currIndex - 1) * 4 + 3], 0, mutex);

                if(mutex == currIndex)
                {
                    float3 current = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
                    float3 other = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex - 1));
                    float3 delta = (current - other);
                    float dist = length(delta);
                    float halfDist = (dist - targetDist) / 2.0;
                    delta = SafeNormalize(delta);
                    if (currIndex == bufferSize - 1)
                    {
                        WriteToPositionsBuffer(positions, currIndex, Float3ToUint3(current + ((halfDist + halfDist) * delta)));
                    }
                    else
                    {
                        WriteToPositionsBuffer(positions, currIndex, Float3ToUint3(current + (halfDist * delta)));
                        WriteToPositionsBuffer(positions, currIndex - 1, Float3ToUint3(other - (halfDist * delta)));
                    }

                    InterlockedExchange(positions[(currIndex-1) * 4 + 3], currIndex - 2, ignored);
                    break;
                }
            }
            
            
            if (currIndex + 1 < bufferSize)
            {
                for(uint k=0; k<100; ++k)
                {
                    InterlockedAdd(positions[(currIndex+1) * 4 + 3], 0, mutex);
                    if(mutex == currIndex)
                    {
                        float3 current = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
                        float3 other = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex + 1));
                        
                        float3 delta = (current - other);
                        float dist = length(delta);
                        float halfDist = (dist - targetDist) / 2.0;
                        delta = SafeNormalize(delta);
                    
                        WriteToPositionsBuffer(positions, currIndex, Float3ToUint3(current + (halfDist * delta)));
                        WriteToPositionsBuffer(positions, currIndex + 1, Float3ToUint3(other - (halfDist * delta)));
                        InterlockedExchange(positions[(currIndex+1) * 4 + 3], currIndex + 2, ignored);
                        break;
                    }
                }
            }
        }
        attributes.position = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
    }

    attributes.position = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
}