#ifndef SIMPLE_ROPE_SAMPLE
#define SIMPLE_ROPE_SAMPLE
#include "../Shared.hlsl"
void SamplePosition(RWStructuredBuffer<int> buffer, uint stripIndex, uint particleCountInStrip, uint index, out float3 position) 
{
    uint currIndex = stripIndex * particleCountInStrip + index;    
    position = Int3ToFloat3(ReadBuffer(buffer, currIndex));
}
#endif