#ifndef SIMPLE_ROPE_WRITE_POS
#define SIMPLE_ROPE_WRITE_POS
#include "../Shared.hlsl"
void WritePositions(inout VFXAttributes attributes, RWStructuredBuffer<int> buffer) 
{
    uint currIndex = attributes.stripIndex * attributes.particleCountInStrip + attributes.particleIndexInStrip;
    WriteToBuffer(buffer, currIndex, Float3ToInt3(attributes.position));    

}
#endif