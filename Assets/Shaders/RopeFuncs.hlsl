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

inline float3 Uint3ToFloat3(float3 value)
{
    return float3(InverseOrderPreservingFloatMap(value.x), InverseOrderPreservingFloatMap(value.y), InverseOrderPreservingFloatMap(value.z));
}

void WriteToPositionsBuffer(RWByteAddressBuffer positions, uint index, uint3 inPosition) {
    uint x,y,z = 0;
    positions.InterlockedExchange(index*12, inPosition.x, x);
    positions.InterlockedExchange(index*12+4, inPosition.y, y);
    positions.InterlockedExchange(index*12+8, inPosition.z, z);
}


void WriteBuffer(VFXAttributes attributes, RWByteAddressBuffer positions, uint index) {    
    uint3 position = Float3ToUint3(attributes.position);
    WriteToPositionsBuffer(positions, index, position);
}

inline uint3 ReadPositionsBuffer(RWByteAddressBuffer positions, uint index) {
    uint x,y,z = 0;
    positions.InterlockedAdd(index * 12, 0, x);
    positions.InterlockedAdd(index * 12 + 4, 0, y);
    positions.InterlockedAdd(index * 12 + 8, 0, z);
    return uint3(x,y,z);
}


void IntegrateVerlet(inout VFXAttributes attributes, float deltaTime)
{
    attributes.position = 2 * attributes.position - attributes.oldPosition + ((deltaTime*deltaTime) * attributes.acceleration);
}


void ReadPosition(inout VFXAttributes attributes, RWByteAddressBuffer positions, uint index) {
    attributes.position = Uint3ToFloat3(ReadPositionsBuffer(positions, index));
}

void UpdateRopeImpl(inout VFXAttributes attributes, RWByteAddressBuffer positions, RWByteAddressBuffer mutexes, float targetDist, uint bufferSize, uint currIndex)
{
    uint ignored = 0;
    uint mutex = 0;
    WriteToPositionsBuffer(positions, currIndex, attributes.position);
    mutexes.InterlockedExchange(currIndex * 4, currIndex - 1, ignored);
    {
        for (uint i = 0; i < 12; ++i) {
        if (currIndex % 2 == 1) 
        {   
            for(uint j=0; j<1000; ++j)
            {
                mutexes.InterlockedAdd((currIndex - 1)*4, 0, mutex);

                if(mutex == currIndex)
                {
                    // float3 current = float3(0.0, 0.0, 0.0);
                    // float3 other = float3(0.0, 0.0, 0.0);
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

                    mutexes.InterlockedExchange((currIndex - 1) * 4, currIndex - 2, ignored);
                    break;
                }
            }
            
            
            if (currIndex + 1 < bufferSize)
            {
                for(uint k=0; k<1000; ++k) 
                {
                    mutexes.InterlockedAdd((currIndex+1) * 4, 0, mutex);
                    if(mutex == currIndex)
                    {
                        float3 current = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
                        float3 other = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex + 1));
                        
                        float3 delta = (current - other);
                        float dist = length(delta);
                        float halfDist = (dist - targetDist) / 2.0;
                        delta = SafeNormalize(delta);
                    
                        WriteToPositionsBuffer(positions, currIndex, current + (halfDist * delta));
                        WriteToPositionsBuffer(positions, currIndex + 1, other - (halfDist * delta));
                        mutexes.InterlockedExchange((currIndex + 1) * 4, currIndex + 2, ignored);
                        break;
                    }
                }
            }
        }
    }
    }
    attributes.position = Uint3ToFloat3(ReadPositionsBuffer(positions, currIndex));
}

void UpdateRope(inout VFXAttributes attributes, RWByteAddressBuffer positions, RWByteAddressBuffer mutexes, float targetDist, uint bufferSize, uint currIndex)
{
    UpdateRopeImpl(attributes, positions, mutexes, targetDist, bufferSize, currIndex);   
}
#endif