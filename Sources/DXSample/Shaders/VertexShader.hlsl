
cbuffer PerFrameConstants : register(b0) {
  float4x4 mvp;
}

struct VSOutput {
  float4 position : SV_POSITION;
  float4 color : COLOR;
};

VSOutput VSMain(float3 position : POSITION, float4 color : COLOR) {
  VSOutput result;

  result.position = mul(float4(position, 1.0), mvp);
  result.color = color;

  return result;
}
