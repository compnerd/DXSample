// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import SwiftCOM
import WinSDK

public class Application {
  class var UseWARP: Bool { false }
  class var BufferCount: UINT { 2 }

  // 720p
  class var Width: UINT { 1280 }
  class var Height: UINT { 720 }

  class var BackBufferFormat: DXGI_FORMAT { DXGI_FORMAT_R8G8B8A8_UNORM }
  class var DepthStencilFormat: DXGI_FORMAT { DXGI_FORMAT_D24_UNORM_S8_UINT }

  public static var shared: Application!

  var window: Window

  var dxgiFactory: SwiftCOM.IDXGIFactory4
  var device: SwiftCOM.ID3D12Device
  var swapChain: SwiftCOM.IDXGISwapChain

  var currentFence: UINT64 = 0
  var fence: SwiftCOM.ID3D12Fence

  var commandQueue: SwiftCOM.ID3D12CommandQueue
  var commandAllocator: SwiftCOM.ID3D12CommandAllocator
  var commandList: SwiftCOM.ID3D12GraphicsCommandList

  var cbvHeap: SwiftCOM.ID3D12DescriptorHeap!
  var dsvHeap: SwiftCOM.ID3D12DescriptorHeap
  var rtvHeap: SwiftCOM.ID3D12DescriptorHeap

  var cbvDescSize: UINT
  var dsvDescSize: UINT
  var rtvDescSize: UINT

  var currentBuffer: Int = 0
  var swapChainBuffers: [SwiftCOM.ID3D12Resource] = []
  var depthStencilBuffer: SwiftCOM.ID3D12Resource!

  var scissor: D3D12_RECT!
  var viewport: D3D12_VIEWPORT!

  var frameCount: UINT64 = 0
  var clock: HighResolutionClock = .init()

  public required init() throws {
    #if DEBUG
    let DXGIFactoryFlags: UINT = UINT(DXGI_CREATE_FACTORY_DEBUG)
    #else
    let DXGIFactoryFlags: UINT = 0
    #endif

    self.window = Window("DirectX Demo", Int(Self.Width), Int(Self.Height))

    // 1. Create factory
    self.dxgiFactory = try CreateDXGIFactory2(DXGIFactoryFlags)

    // 3. Create the device.
    if let device: SwiftCOM.ID3D12Device =
      try? D3D12CreateDevice(nil, D3D_FEATURE_LEVEL_11_0)
    {
      self.device = device
    } else {
      self.device =
        try D3D12CreateDevice(
          self.dxgiFactory.EnumWarpAdapter().QueryInterface(),
          D3D_FEATURE_LEVEL_11_0)
    }

    #if DEBUG
    if let IQ: SwiftCOM.ID3D12InfoQueue = try? self.device.QueryInterface() {
      _ = try? IQ.SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_CORRUPTION, true)
      _ = try? IQ.SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_ERROR, true)
      _ = try? IQ.SetBreakOnSeverity(D3D12_MESSAGE_SEVERITY_WARNING, true)
    }
    #endif

    // 4. Setup the command queues.
    self.fence = try self.device.CreateFence(0, D3D12_FENCE_FLAG_NONE)

    self.commandQueue = try self.device.CreateCommandQueue(
      D3D12_COMMAND_QUEUE_DESC(
        Type: D3D12_COMMAND_LIST_TYPE_DIRECT,
        Priority: D3D12_COMMAND_QUEUE_PRIORITY_NORMAL.rawValue,
        Flags: D3D12_COMMAND_QUEUE_FLAG_NONE,
        NodeMask: 0))
    self.commandAllocator = try self.device.CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT)
    self.commandList = try self.device.CreateCommandList(
      0, D3D12_COMMAND_LIST_TYPE_DIRECT, self.commandAllocator, nil)
    // Initialize the command list into a closed state.  We reset the command
    // list when rendering, which requires the command list be closed.
    try! self.commandList.Close()

    // 6. Create descriptor heaps
    self.dsvHeap = try self.device.CreateDescriptorHeap(
      D3D12_DESCRIPTOR_HEAP_DESC(
        Type: D3D12_DESCRIPTOR_HEAP_TYPE_DSV,
        NumDescriptors: 1,
        Flags: D3D12_DESCRIPTOR_HEAP_FLAG_NONE,
        NodeMask: 0))
    self.rtvHeap = try self.device.CreateDescriptorHeap(
      D3D12_DESCRIPTOR_HEAP_DESC(
        Type: D3D12_DESCRIPTOR_HEAP_TYPE_RTV,
        NumDescriptors: Self.BufferCount,
        Flags: D3D12_DESCRIPTOR_HEAP_FLAG_NONE,
        NodeMask: 0))

    self.rtvDescSize = try self.device.GetDescriptorHandleIncrementSize(
      D3D12_DESCRIPTOR_HEAP_TYPE_RTV)
    self.dsvDescSize = try self.device.GetDescriptorHandleIncrementSize(
      D3D12_DESCRIPTOR_HEAP_TYPE_DSV)
    self.cbvDescSize = try self.device.GetDescriptorHandleIncrementSize(
      D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV)

    // 5. Setup Swap Chain.
    self.swapChain =
      try self.dxgiFactory.CreateSwapChain(
        self.commandQueue,
        DXGI_SWAP_CHAIN_DESC(
          BufferDesc: DXGI_MODE_DESC(
            Width: UINT(Self.Width),
            Height: UINT(Self.Height),
            RefreshRate: DXGI_RATIONAL(Numerator: 60, Denominator: 1),
            Format: Self.BackBufferFormat,
            ScanlineOrdering: DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED,
            Scaling: DXGI_MODE_SCALING_UNSPECIFIED),
          SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
          BufferUsage: DXGI_USAGE_RENDER_TARGET_OUTPUT,
          BufferCount: Self.BufferCount,
          OutputWindow: self.window.hWnd,
          Windowed: true,
          SwapEffect: DXGI_SWAP_EFFECT_FLIP_DISCARD,
          Flags: UINT(DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH.rawValue)))

    try self.resize(width: Int(Self.Width), height: Int(Self.Height))
  }

  deinit {
    try? self.flushCommandQueue()
  }

  public func resize(width: Int, height: Int) throws {
    try self.flushCommandQueue()

    try self.commandList.Reset(self.commandAllocator, nil)

    self.swapChainBuffers.removeAll()
    // self.depthStencilBuffer = .init()

    try self.swapChain.ResizeBuffers(
      Self.BufferCount, UINT(width), UINT(height),
      Self.BackBufferFormat,
      UINT(DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH.rawValue))
    self.currentBuffer = 0

    var hRTV: D3D12_CPU_DESCRIPTOR_HANDLE =
      try! self.rtvHeap.GetCPUDescriptorHandleForHeapStart()
    try (0..<Self.BufferCount).forEach {
      try self.swapChainBuffers.append(self.swapChain.GetBuffer($0))
      try! self.device.CreateRenderTargetView(self.swapChainBuffers.last!, nil, hRTV)
      hRTV.Offset(1, self.rtvDescSize)
    }

    self.depthStencilBuffer = try self.device.CreateCommittedResource(
      D3D12_HEAP_PROPERTIES(
        Type: D3D12_HEAP_TYPE_DEFAULT,
        CPUPageProperty: D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
        MemoryPoolPreference: D3D12_MEMORY_POOL_UNKNOWN,
        CreationNodeMask: 1,
        VisibleNodeMask: 1),
      D3D12_HEAP_FLAG_NONE,
      D3D12_RESOURCE_DESC(
        Dimension: D3D12_RESOURCE_DIMENSION_TEXTURE2D,
        Alignment: 0,
        Width: UINT64(width),
        Height: UINT(height),
        DepthOrArraySize: 1,
        MipLevels: 1,
        Format: DXGI_FORMAT_R24G8_TYPELESS,
        SampleDesc: DXGI_SAMPLE_DESC(Count: 1, Quality: 0),
        Layout: D3D12_TEXTURE_LAYOUT_UNKNOWN,
        Flags: D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL),
      D3D12_RESOURCE_STATE_COMMON,
      D3D12_CLEAR_VALUE(
        Format: Self.DepthStencilFormat,
        DepthStencil: D3D12_DEPTH_STENCIL_VALUE(
          Depth: 1.0,
          Stencil: 0)))
    try self.device.CreateDepthStencilView(
      self.depthStencilBuffer,
      D3D12_DEPTH_STENCIL_VIEW_DESC(
        Format: Self.DepthStencilFormat,
        ViewDimension: D3D12_DSV_DIMENSION_TEXTURE2D,
        Flags: D3D12_DSV_FLAG_NONE,
        Texture2D: D3D12_TEX2D_DSV(MipSlice: 0)),
      self.dsvHeap.GetCPUDescriptorHandleForHeapStart())

    try! self.commandList.ResourceBarrier(
      1,
      D3D12_RESOURCE_BARRIER(
        Type: D3D12_RESOURCE_BARRIER_TYPE_TRANSITION,
        Flags: D3D12_RESOURCE_BARRIER_FLAG_NONE,
        Transition: D3D12_RESOURCE_TRANSITION_BARRIER(
          pResource: RawPointer(self.depthStencilBuffer),
          Subresource: D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
          StateBefore: D3D12_RESOURCE_STATE_COMMON,
          StateAfter: D3D12_RESOURCE_STATE_DEPTH_WRITE)))

    try self.commandList.Close()
    try! self.commandQueue.ExecuteCommandLists([self.commandList])

    try self.flushCommandQueue()

    self.viewport = D3D12_VIEWPORT(
      TopLeftX: 0, TopLeftY: 0, Width: FLOAT(width), Height: FLOAT(height), MinDepth: 0.0,
      MaxDepth: 1.0)
    self.scissor = D3D12_RECT(left: 0, top: 0, right: LONG(width), bottom: LONG(height))
  }

  public func flushCommandQueue() throws {
    self.currentFence += 1
    try self.commandQueue.Signal(self.fence, self.currentFence)
    if try! self.fence.GetCompletedValue() < self.currentFence {
      let handle: HANDLE = CreateEventW(nil, false, false, nil)
      defer { _ = CloseHandle(handle) }

      try self.fence.SetEventOnCompletion(self.currentFence, handle)
      _ = WaitForSingleObject(handle, INFINITE)
    }
  }
}

extension Application {
  public static func main() throws {
    _ = SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

    #if DEBUG
    if let DI: SwiftCOM.ID3D12Debug = try? D3D12GetDebugInterface() {
      try? DI.EnableDebugLayer()
    }
    #endif

    Application.shared = try Self()

    var msg: MSG = MSG()
    repeat {
      if PeekMessageW(&msg, nil, 0, 0, UINT(PM_REMOVE)) {
        TranslateMessage(&msg)
        DispatchMessageW(&msg)
      } else {
        Application.shared.window.delegate?.update()
        try! Application.shared.window.delegate?.render()
      }
    } while msg.message != WM_QUIT

    // NOTE: we explicitly nil out the application to allow the destructor to
    // run deterministically.  Without this, there is no guarantee that the
    // `deinit` will be executed.
    Application.shared = nil

    #if DEBUG
    if let DI: SwiftCOM.IDXGIDebug = try? DXGIGetDebugInterface1(0) {
      try? DI.ReportLiveObjects(DXGI_DEBUG_ALL, DXGI_DEBUG_RLO_IGNORE_INTERNAL)
    }
    #endif
  }
}
