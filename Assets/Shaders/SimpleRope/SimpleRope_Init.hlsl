#ifndef SIMPLE_ROPE_INIT 
#define SIMPLE_ROPE_INIT
#include "../Shared.hlsl"
void InitializeSimpleRope(inout VFXAttributes attributes, RWStructuredBuffer<uint> stripBuffer, uint particleCountInStrip, uint particleIndexInStrip) 
{
    if(particleIndexInStrip == 0) 
    {        
        uint startIndex = 0;
        InterlockedAdd(stripBuffer[0], particleCountInStrip, startIndex);
        stripBuffer[attributes.stripIndex + 1] = startIndex;
    }
}
#endif