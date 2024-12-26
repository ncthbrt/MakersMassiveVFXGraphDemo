#ifndef SIMPLE_ROPE_SAMPLE
#define SIMPLE_ROPE_SAMPLE
#include "../Shared.hlsl"
void SamplePosition(RWStructuredBuffer<uint> stripBuffer, RWStructuredBuffer<int> buffer, uint stripIndex, uint index, out float3 position) 
{
    uint currIndex = stripBuffer[stripIndex + 1] + index;
    position = Int3ToFloat3(ReadBuffer(buffer, currIndex));
}
#endif