// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import SwiftCOM
import WinSDK

extension D3D12_BLEND_DESC {
  @_transparent
  internal static var `default`: D3D12_BLEND_DESC {
    D3D12_BLEND_DESC(
      AlphaToCoverageEnable: false,
      IndependentBlendEnable: false,
      RenderTarget: (
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue)),
        D3D12_RENDER_TARGET_BLEND_DESC(
          BlendEnable: false,
          LogicOpEnable: false,
          SrcBlend: D3D12_BLEND_ONE,
          DestBlend: D3D12_BLEND_ZERO,
          BlendOp: D3D12_BLEND_OP_ADD,
          SrcBlendAlpha: D3D12_BLEND_ONE,
          DestBlendAlpha: D3D12_BLEND_ZERO,
          BlendOpAlpha: D3D12_BLEND_OP_ADD,
          LogicOp: D3D12_LOGIC_OP_NOOP,
          RenderTargetWriteMask: UINT8(D3D12_COLOR_WRITE_ENABLE_ALL.rawValue))
      ))
  }
}

extension D3D12_HEAP_PROPERTIES {
  @_transparent
  internal init(_ type: D3D12_HEAP_TYPE, creationMask: UINT = 1, nodeMask: UINT = 1) {
    self = D3D12_HEAP_PROPERTIES(
      Type: type,
      CPUPageProperty: D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
      MemoryPoolPreference: D3D12_MEMORY_POOL_UNKNOWN,
      CreationNodeMask: creationMask,
      VisibleNodeMask: nodeMask)
  }
}

extension D3D12_RASTERIZER_DESC {
  @_transparent
  internal static var `default`: D3D12_RASTERIZER_DESC {
    D3D12_RASTERIZER_DESC(
      FillMode: D3D12_FILL_MODE_SOLID,
      CullMode: D3D12_CULL_MODE_BACK,
      FrontCounterClockwise: false,
      DepthBias: D3D12_DEFAULT_DEPTH_BIAS,
      DepthBiasClamp: D3D12_DEFAULT_DEPTH_BIAS_CLAMP,
      SlopeScaledDepthBias: D3D12_DEFAULT_SLOPE_SCALED_DEPTH_BIAS,
      DepthClipEnable: true,
      MultisampleEnable: false,
      AntialiasedLineEnable: false,
      ForcedSampleCount: 0,
      ConservativeRaster: D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF)
  }
}

extension D3D12_RESOURCE_BARRIER {
  @_transparent
  internal init(
    Type: D3D12_RESOURCE_BARRIER_TYPE,
    Flags: D3D12_RESOURCE_BARRIER_FLAGS,
    Transition: D3D12_RESOURCE_TRANSITION_BARRIER
  ) {
    self = .init()
    self.Type = Type
    self.Flags = Flags
    self.Transition = Transition
  }
}

extension D3D12_ROOT_PARAMETER {
  internal init(
    ParameterType: D3D12_ROOT_PARAMETER_TYPE,
    DescriptorTable: D3D12_ROOT_DESCRIPTOR_TABLE,
    ShaderVisibility: D3D12_SHADER_VISIBILITY
  ) {
    self = .init()
    self.ParameterType = ParameterType
    self.DescriptorTable = DescriptorTable
    self.ShaderVisibility = ShaderVisibility
  }
}

extension D3D12_ROOT_SIGNATURE_DESC {
  // FIXME(compnerd) is there a way to enforce lifetime of `ranges` to extend
  // beyond the function?
  @_transparent
  internal init(
    _ parameters: [D3D12_ROOT_PARAMETER],
    samplers: [D3D12_STATIC_SAMPLER_DESC] = [],
    flags: D3D12_ROOT_SIGNATURE_FLAGS = D3D12_ROOT_SIGNATURE_FLAG_NONE
  ) {
    self = parameters.withUnsafeBufferPointer { parameters in
      samplers.withUnsafeBufferPointer { samplers in
        D3D12_ROOT_SIGNATURE_DESC(
          NumParameters: UINT(parameters.count),
          pParameters: parameters.baseAddress,
          NumStaticSamplers: UINT(samplers.count),
          pStaticSamplers: samplers.baseAddress,
          Flags: flags)
      }
    }
  }
}

extension D3D12_CLEAR_VALUE {
  @_transparent
  internal init(
    Format: DXGI_FORMAT,
    DepthStencil: D3D12_DEPTH_STENCIL_VALUE
  ) {
    self = .init()
    self.Format = Format
    self.DepthStencil = DepthStencil
  }
}

extension D3D12_DEPTH_STENCIL_VIEW_DESC {
  @_transparent
  internal init(
    Format: DXGI_FORMAT,
    ViewDimension: D3D12_DSV_DIMENSION,
    Flags: D3D12_DSV_FLAGS,
    Texture2D: D3D12_TEX2D_DSV
  ) {
    self = .init()
    self.Format = Format
    self.ViewDimension = ViewDimension
    self.Flags = Flags
    self.Texture2D = Texture2D
  }
}

extension D3D12_DEPTH_STENCIL_DESC {
  @_transparent
  internal static var `default`: D3D12_DEPTH_STENCIL_DESC {
    D3D12_DEPTH_STENCIL_DESC(
      DepthEnable: true,
      DepthWriteMask: D3D12_DEPTH_WRITE_MASK_ALL,
      DepthFunc: D3D12_COMPARISON_FUNC_LESS,
      StencilEnable: false,
      StencilReadMask: UINT8(D3D12_DEFAULT_STENCIL_READ_MASK),
      StencilWriteMask: UINT8(D3D12_DEFAULT_STENCIL_WRITE_MASK),
      FrontFace: D3D12_DEPTH_STENCILOP_DESC(
        StencilFailOp: D3D12_STENCIL_OP_KEEP,
        StencilDepthFailOp: D3D12_STENCIL_OP_KEEP,
        StencilPassOp: D3D12_STENCIL_OP_KEEP,
        StencilFunc: D3D12_COMPARISON_FUNC_ALWAYS),
      BackFace: D3D12_DEPTH_STENCILOP_DESC(
        StencilFailOp: D3D12_STENCIL_OP_KEEP,
        StencilDepthFailOp: D3D12_STENCIL_OP_KEEP,
        StencilPassOp: D3D12_STENCIL_OP_KEEP,
        StencilFunc: D3D12_COMPARISON_FUNC_ALWAYS))
  }
}
