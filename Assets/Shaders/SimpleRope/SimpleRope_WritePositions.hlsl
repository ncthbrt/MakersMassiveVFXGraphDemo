#ifndef SIMPLE_ROPE_WRITE_POS
#define SIMPLE_ROPE_WRITE_POS
#include "../Shared.hlsl"
void WritePositions(inout VFXAttributes attributes, RWStructuredBuffer<uint> stripBuffer, RWStructuredBuffer<int> buffer) 
{    
    uint currIndex = stripBuffer[attributes.stripIndex + 1] + attributes.particleIndexInStrip;
    WriteToBuffer(buffer, currIndex, Float3ToInt3(attributes.position));
}
#endif