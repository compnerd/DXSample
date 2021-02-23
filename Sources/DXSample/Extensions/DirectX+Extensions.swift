// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import SwiftCOM
import WinSDK

extension SwiftCOM.IDXGIFactory6 {
  public func GetHardwareAdapter(bRequestHighPerformanceAdapter: Bool) throws -> SwiftCOM
    .IDXGIAdapter1?
  {
    let DXGI_ADAPTER_FLAG_SOFTWARE: DWORD = DWORD(DXGI_ADAPTER_FLAG_SOFTWARE.rawValue)

    var uiAdapter: UINT = 0
    while let pAdapter: SwiftCOM.IDXGIAdapter1 =
      try? EnumAdapterByGpuPreference(
        uiAdapter,
        bRequestHighPerformanceAdapter
          ? DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE
          : DXGI_GPU_PREFERENCE_UNSPECIFIED)
    {
      if let desc: DXGI_ADAPTER_DESC1 = try? pAdapter.GetDesc1() {
        if desc.Flags & DXGI_ADAPTER_FLAG_SOFTWARE == 0 {
          return pAdapter
        }
      }
      _ = try? pAdapter.Release()
      uiAdapter += 1
    }
    return nil
  }
}

extension D3D12_CPU_DESCRIPTOR_HANDLE {
  public mutating func Offset(_ descriptors: INT, _ size: UINT) {
    self.ptr = SIZE_T(INT64(self.ptr) + INT64(descriptors) * INT64(size))
  }

  public mutating func Offset(_ size: INT) {
    self.ptr = SIZE_T(INT64(self.ptr) + INT64(size))
  }
}
