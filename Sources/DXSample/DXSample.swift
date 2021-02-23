// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import Foundation
import SwiftCOM
import WinSDK

// Internal Types
private typealias Vertex = (FLOAT3, FLOAT4)  // (position, color)
private typealias Index = UINT16

@main
final class Demo: Application {
  private var constants: (mvp: FLOAT4X4, ()) = (mvp: FLOAT4X4_identity, ())
  private var constantBuffer: SwiftCOM.ID3D12Resource?
  private var constantBufferView: UnsafeMutableRawPointer?

  private var rootSignature: SwiftCOM.ID3D12RootSignature?

  private var vsByteCode: SwiftCOM.ID3DBlob?
  private var psByteCode: SwiftCOM.ID3DBlob?

  private var vertexBuffer: SwiftCOM.ID3D12Resource?
  private var vertexBufferGPU: SwiftCOM.ID3D12Resource?

  private var indexBuffer: SwiftCOM.ID3D12Resource?
  private var indexBufferGPU: SwiftCOM.ID3D12Resource?

  private var pipelineState: SwiftCOM.ID3D12PipelineState?

  private let vertices: [Vertex] = [
    ((-1.0, -1.0, -1.0), (0.0, 0.0, 0.0, 1.0)),
    ((-1.0, 1.0, -1.0), (0.0, 1.0, 0.0, 1.0)),
    ((1.0, 1.0, -1.0), (1.0, 1.0, 0.0, 1.0)),
    ((1.0, -1.0, -1.0), (1.0, 0.0, 0.0, 1.0)),
    ((-1.0, -1.0, 1.0), (0.0, 0.0, 1.0, 1.0)),
    ((-1.0, 1.0, 1.0), (0.0, 1.0, 1.0, 1.0)),
    ((1.0, 1.0, 1.0), (1.0, 1.0, 1.0, 1.0)),
    ((1.0, -1.0, 1.0), (1.0, 0.0, 1.0, 1.0)),
  ]

  private let indicies: [Index] = [
    0, 1, 2, 0, 2, 3,  // front face
    4, 6, 5, 4, 7, 6,  // back face
    4, 5, 1, 4, 1, 0,  // left face
    3, 2, 6, 3, 6, 7,  // right face
    1, 5, 6, 1, 6, 2,  // top face
    4, 0, 3, 4, 3, 7,  // bottom face
  ]

  private var fov: Float = 45.0
  private var world: FLOAT4X4 = FLOAT4X4_identity
  private var view: FLOAT4X4 = FLOAT4X4_identity
  private var projection: FLOAT4X4 = FLOAT4X4_identity

  private var radius: FLOAT = 5.0
  private var phi: FLOAT = 1.2
  private var theta: FLOAT = 4.0
  private var previousMousePosition: (FLOAT, FLOAT) = (0, 0)

  public required init() throws {
    try super.init()

    try self.commandList.Reset(self.commandAllocator, nil)

    // Descriptor Heaps
    self.cbvHeap = try self.device.CreateDescriptorHeap(
      D3D12_DESCRIPTOR_HEAP_DESC(
        Type: D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV,
        NumDescriptors: 1,
        Flags: D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE,
        NodeMask: 0))

    // Constant Buffers
    try withUnsafeBytes(of: &self.constants) {
      self.constantBuffer = try self.device.CreateCommittedResource(
        D3D12_HEAP_PROPERTIES(
          Type: D3D12_HEAP_TYPE_UPLOAD,
          CPUPageProperty: D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
          MemoryPoolPreference: D3D12_MEMORY_POOL_UNKNOWN,
          CreationNodeMask: 1,
          VisibleNodeMask: 1),
        D3D12_HEAP_FLAG_NONE,
        D3D12_RESOURCE_DESC(
          Dimension: D3D12_RESOURCE_DIMENSION_BUFFER,
          Alignment: 0,
          Width: UINT64(($0.count + 255) & ~255),
          Height: 1,
          DepthOrArraySize: 1,
          MipLevels: 1,
          Format: DXGI_FORMAT_UNKNOWN,
          SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
          Layout: D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
          Flags: D3D12_RESOURCE_FLAG_NONE),
        D3D12_RESOURCE_STATE_GENERIC_READ,
        nil)
      self.constantBufferView = try self.constantBuffer!.Map(0, nil)
      try self.device.CreateConstantBufferView(
        D3D12_CONSTANT_BUFFER_VIEW_DESC(
          BufferLocation: self.constantBuffer!.GetGPUVirtualAddress(),
          SizeInBytes: UINT(($0.count + 255) & ~255)),
        self.cbvHeap.GetCPUDescriptorHandleForHeapStart())
    }

    // Root Signature
    let ranges: [D3D12_DESCRIPTOR_RANGE] = [
      D3D12_DESCRIPTOR_RANGE(
        RangeType: D3D12_DESCRIPTOR_RANGE_TYPE_CBV,
        NumDescriptors: 1,
        BaseShaderRegister: 0,
        RegisterSpace: 0,
        OffsetInDescriptorsFromTableStart: D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND)
    ]
    let signature: SwiftCOM.ID3DBlob = try ranges.withUnsafeBufferPointer {
      let parameters: [D3D12_ROOT_PARAMETER] = [
        D3D12_ROOT_PARAMETER(
          ParameterType: D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE,
          DescriptorTable: D3D12_ROOT_DESCRIPTOR_TABLE(
            NumDescriptorRanges: UINT($0.count),
            pDescriptorRanges: $0.baseAddress),
          ShaderVisibility: D3D12_SHADER_VISIBILITY_ALL)
      ]
      return try parameters.withUnsafeBufferPointer {
        try D3D12SerializeRootSignature(
          D3D12_ROOT_SIGNATURE_DESC(
            NumParameters: UINT($0.count),
            pParameters: $0.baseAddress,
            NumStaticSamplers: 0,
            pStaticSamplers: nil,
            Flags: D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT),
          D3D_ROOT_SIGNATURE_VERSION_1
        ).0
      }
    }

    self.rootSignature = try self.device.CreateRootSignature(
      0, signature.GetBufferPointer(), signature.GetBufferSize())

    // Shaders
    #if DEBUG
    let Flags: UINT = UINT(D3DCOMPILE_DEBUG | D3DCOMPILE_SKIP_OPTIMIZATION)
    #else
    let Flags: UINT = 0
    #endif

    let VertexShader: String =
      Bundle.module.url(forResource: "Shaders/VertexShader", withExtension: "hlsl")!
      .withUnsafeFileSystemRepresentation {
        String(cString: $0!)
      }
    self.vsByteCode = try D3DCompileFromFile(VertexShader, [], nil, "VSMain", "vs_5_0", Flags, 0).0

    let PixelShader: String =
      Bundle.module.url(forResource: "Shaders/PixelShader", withExtension: "hlsl")!
      .withUnsafeFileSystemRepresentation {
        String(cString: $0!)
      }
    self.psByteCode = try D3DCompileFromFile(PixelShader, [], nil, "PSMain", "ps_5_0", Flags, 0).0

    // Geometry
    try self.vertices.withUnsafeBytes {
      self.vertexBuffer = try self.device.CreateCommittedResource(
        D3D12_HEAP_PROPERTIES(
          Type: D3D12_HEAP_TYPE_UPLOAD,
          CPUPageProperty: D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
          MemoryPoolPreference: D3D12_MEMORY_POOL_UNKNOWN,
          CreationNodeMask: 1,
          VisibleNodeMask: 1),
        D3D12_HEAP_FLAG_NONE,
        D3D12_RESOURCE_DESC(
          Dimension: D3D12_RESOURCE_DIMENSION_BUFFER,
          Alignment: 0,
          Width: UINT64($0.count),
          Height: 1,
          DepthOrArraySize: 1,
          MipLevels: 1,
          Format: DXGI_FORMAT_UNKNOWN,
          SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
          Layout: D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
          Flags: D3D12_RESOURCE_FLAG_NONE),
        D3D12_RESOURCE_STATE_GENERIC_READ,
        nil)
      let data: UnsafeMutableRawPointer? = try self.vertexBuffer?.Map(0, nil)
      _ = memcpy(data, $0.baseAddress, $0.count)
      try self.vertexBuffer?.Unmap(0, nil)
    }

    try self.indicies.withUnsafeBytes {
      self.indexBuffer = try self.device.CreateCommittedResource(
        D3D12_HEAP_PROPERTIES(
          Type: D3D12_HEAP_TYPE_UPLOAD,
          CPUPageProperty: D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
          MemoryPoolPreference: D3D12_MEMORY_POOL_UNKNOWN,
          CreationNodeMask: 1,
          VisibleNodeMask: 1),
        D3D12_HEAP_FLAG_NONE,
        D3D12_RESOURCE_DESC(
          Dimension: D3D12_RESOURCE_DIMENSION_BUFFER,
          Alignment: 0,
          Width: UINT64($0.count),
          Height: 1,
          DepthOrArraySize: 1,
          MipLevels: 1,
          Format: DXGI_FORMAT_UNKNOWN,
          SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
          Layout: D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
          Flags: D3D12_RESOURCE_FLAG_NONE),
        D3D12_RESOURCE_STATE_GENERIC_READ,
        nil)
      let data: UnsafeMutableRawPointer? = try self.indexBuffer?.Map(0, nil)
      _ = memcpy(data, $0.baseAddress, $0.count)
      try self.indexBuffer?.Unmap(0, nil)
    }

    // Pipeline State Object
    self.pipelineState =
      try "POSITION".withCString { pszPosition in
        try "COLOR".withCString { pszColor in
          try [
            D3D12_INPUT_ELEMENT_DESC(
              SemanticName: pszPosition,
              SemanticIndex: 0,
              Format: DXGI_FORMAT_R32G32B32_FLOAT,
              InputSlot: 0,
              AlignedByteOffset: 0,
              InputSlotClass: D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA,
              InstanceDataStepRate: 0),
            D3D12_INPUT_ELEMENT_DESC(
              SemanticName: pszColor,
              SemanticIndex: 0,
              Format: DXGI_FORMAT_R32G32B32A32_FLOAT,
              InputSlot: 0,
              AlignedByteOffset: 12,
              InputSlotClass: D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA,
              InstanceDataStepRate: 0),
          ].withUnsafeBufferPointer {
            try self.device.CreateGraphicsPipelineState(
              D3D12_GRAPHICS_PIPELINE_STATE_DESC(
                pRootSignature: RawPointer(self.rootSignature),
                VS: D3D12_SHADER_BYTECODE(
                  pShaderBytecode: self.vsByteCode!.GetBufferPointer(),
                  BytecodeLength: SIZE_T(self.vsByteCode!.GetBufferSize())),
                PS: D3D12_SHADER_BYTECODE(
                  pShaderBytecode: self.psByteCode!.GetBufferPointer(),
                  BytecodeLength: SIZE_T(self.psByteCode!.GetBufferSize())),
                DS: D3D12_SHADER_BYTECODE(),
                HS: D3D12_SHADER_BYTECODE(),
                GS: D3D12_SHADER_BYTECODE(),
                StreamOutput: D3D12_STREAM_OUTPUT_DESC(),
                BlendState: .default,
                SampleMask: UINT.max,
                RasterizerState: .default,
                DepthStencilState: D3D12_DEPTH_STENCIL_DESC(),
                InputLayout: D3D12_INPUT_LAYOUT_DESC(
                  pInputElementDescs: $0.baseAddress,
                  NumElements: UINT($0.count)),
                IBStripCutValue: D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED,
                PrimitiveTopologyType: D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
                NumRenderTargets: 1,
                RTVFormats: (
                  Self.BackBufferFormat,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN,
                  DXGI_FORMAT_UNKNOWN
                ),
                DSVFormat: Self.DepthStencilFormat,
                SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
                NodeMask: 0,
                CachedPSO: D3D12_CACHED_PIPELINE_STATE(),
                Flags: D3D12_PIPELINE_STATE_FLAG_NONE)) as SwiftCOM.ID3D12PipelineState
          }
        }
      }

    try self.commandList.Close()
    try! self.commandQueue.ExecuteCommandLists([self.commandList])

    try! self.flushCommandQueue()

    self.window.delegate = self
    _ = ShowWindow(window.hWnd, SW_SHOWDEFAULT)
    _ = UpdateWindow(window.hWnd)
  }

  deinit {
    try? self.constantBuffer?.Unmap(0, nil)
  }

  override public func resize(width: Int, height: Int) throws {
    try super.resize(width: width, height: height)
  }
}

extension Demo: WindowDelegate {
  public func render() throws {
    try self.commandAllocator.Reset()

    try self.commandList.Reset(self.commandAllocator, self.pipelineState)

    try! self.commandList.RSSetViewports(1, &self.viewport)
    try! self.commandList.RSSetScissorRects(1, &self.scissor)

    try! self.commandList.ResourceBarrier(
      1,
      D3D12_RESOURCE_BARRIER(
        Type: D3D12_RESOURCE_BARRIER_TYPE_TRANSITION,
        Flags: D3D12_RESOURCE_BARRIER_FLAG_NONE,
        Transition: D3D12_RESOURCE_TRANSITION_BARRIER(
          pResource: RawPointer(self.swapChainBuffers[self.currentBuffer]),
          Subresource: D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
          StateBefore: D3D12_RESOURCE_STATE_PRESENT,
          StateAfter: D3D12_RESOURCE_STATE_RENDER_TARGET)))

    var hRTV: D3D12_CPU_DESCRIPTOR_HANDLE = try! self.rtvHeap.GetCPUDescriptorHandleForHeapStart()
    hRTV.Offset(INT(self.currentBuffer), self.rtvDescSize)
    try! self.commandList.ClearRenderTargetView(hRTV, (0.2, 0.4, 0.6, 1.0), 0, nil)

    try! self.commandList.ClearDepthStencilView(
      self.dsvHeap.GetCPUDescriptorHandleForHeapStart(),
      D3D12_CLEAR_FLAGS(
        rawValue: D3D12_CLEAR_FLAG_DEPTH.rawValue | D3D12_CLEAR_FLAG_STENCIL.rawValue), 1.0, 0, 0,
      nil)

    var hDSV: D3D12_CPU_DESCRIPTOR_HANDLE = try! self.dsvHeap.GetCPUDescriptorHandleForHeapStart()
    try! self.commandList.OMSetRenderTargets(1, &hRTV, true, &hDSV)

    try! self.commandList.SetDescriptorHeaps([self.cbvHeap])

    try! self.commandList.SetGraphicsRootSignature(self.rootSignature)

    var vertexBufferView: D3D12_VERTEX_BUFFER_VIEW = self.vertices.withUnsafeBytes {
      D3D12_VERTEX_BUFFER_VIEW(
        BufferLocation: try! self.vertexBuffer!.GetGPUVirtualAddress(),
        SizeInBytes: UINT($0.count),
        StrideInBytes: UINT(MemoryLayout<Vertex>.stride))
    }
    var indexBufferView: D3D12_INDEX_BUFFER_VIEW = self.indicies.withUnsafeBytes {
      D3D12_INDEX_BUFFER_VIEW(
        BufferLocation: try! self.indexBuffer!.GetGPUVirtualAddress(),
        SizeInBytes: UINT($0.count),
        Format: DXGI_FORMAT_R16_UINT)
    }
    try! self.commandList.IASetVertexBuffers(0, 1, &vertexBufferView)
    try! self.commandList.IASetIndexBuffer(&indexBufferView)
    try! self.commandList.IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST)

    try! self.commandList.SetGraphicsRootDescriptorTable(
      0, self.cbvHeap.GetGPUDescriptorHandleForHeapStart())

    try! self.commandList.DrawIndexedInstanced(UINT(self.indicies.count), 1, 0, 0, 0)

    try! self.commandList.ResourceBarrier(
      1,
      D3D12_RESOURCE_BARRIER(
        Type: D3D12_RESOURCE_BARRIER_TYPE_TRANSITION,
        Flags: D3D12_RESOURCE_BARRIER_FLAG_NONE,
        Transition: D3D12_RESOURCE_TRANSITION_BARRIER(
          pResource: RawPointer(self.swapChainBuffers[self.currentBuffer]),
          Subresource: D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
          StateBefore: D3D12_RESOURCE_STATE_RENDER_TARGET,
          StateAfter: D3D12_RESOURCE_STATE_PRESENT)))

    try self.commandList.Close()

    try! self.commandQueue.ExecuteCommandLists([self.commandList])

    try self.swapChain.Present(0, 0)

    self.currentBuffer = (self.currentBuffer + 1) % Int(Self.BufferCount)

    try! self.flushCommandQueue()
  }

  public func update() {
    self.clock.tick()
    self.frameCount += 1

    if self.clock.sigma.seconds > 1 {
      let fps = Double(self.frameCount) / Double(self.clock.sigma.seconds)
      self.window.title = "DirectX Demo - \(fps) FPS"

      self.frameCount = 0
      self.clock.reset()
    }

    // Spherical -> Cartesian
    let x: FLOAT = self.radius * sin(self.phi) * cos(self.theta)
    let y: FLOAT = self.radius * cos(self.phi)
    let z: FLOAT = self.radius * sin(self.phi) * sin(self.theta)

    self.projection = XMMatrixPerspectiveFovLH(
      XMConvertToRadians(self.fov),
      Float(self.window.width) / Float(self.window.height),
      1.0,
      1000.0)

    // self.view = XMMatrixLookAtLH((5.0, 5.0, -5.0, 1.0),
    //                              (0.0, 0.0, 0.0, 0.0),
    //                              (0.0, 1.0, 0.0, 0.0))
    self.view = XMMatrixLookAtLH((x, y, z, 1.0), FLOAT4_zero, (0.0, 1.0, 0.0, 0.0))

    self.constants.mvp = XMMatrixTranspose(self.world * self.view * self.projection)
    _ = memcpy(self.constantBufferView, &self.constants, MemoryLayout.size(ofValue: self.constants))
  }

  public func mouse(movedTo x: WORD, _ y: WORD, virtualKeyPress: WORD) {
    if virtualKeyPress & WORD(MK_LBUTTON) == WORD(MK_LBUTTON) {
      let dx = XMConvertToRadians(0.25 * (FLOAT(x) - self.previousMousePosition.0))
      let dy = XMConvertToRadians(0.25 * (FLOAT(y) - self.previousMousePosition.1))

      self.theta -= dx
      self.phi -= dy

      self.phi = self.phi.clamped(to: 0.1...(.pi - 0.1))
    }

    self.previousMousePosition = (FLOAT(x), FLOAT(y))
  }
}

extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    return min(max(self, range.lowerBound), range.upperBound)
  }
}
