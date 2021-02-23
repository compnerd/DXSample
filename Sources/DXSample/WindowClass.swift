// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import WinSDK

internal typealias WindowProc =
  @convention(c) (HWND?, UINT, WPARAM, LPARAM) -> LRESULT

internal class WindowClass {
  internal var name: [WCHAR]

  internal var hInstance: HINSTANCE?
  internal var value: WNDCLASSEXW!
  internal var atom: ATOM?

  public init(
    hInst hInstance: HINSTANCE, name: String,
    WindowProc lpfnWindowProc: WindowProc? = DefWindowProcW,
    style: UInt32 = 0, hbrBackground: HBRUSH? = nil,
    hCursor: HCURSOR? = nil
  ) {
    self.name = name.wide

    self.hInstance = hInstance
    self.name.withUnsafeBufferPointer {
      self.value = WNDCLASSEXW(
        cbSize: UINT(MemoryLayout<WNDCLASSEXW>.size),
        style: style,
        lpfnWndProc: lpfnWindowProc,
        cbClsExtra: 0,
        cbWndExtra: 0,
        hInstance: hInstance,
        hIcon: nil,
        hCursor: hCursor,
        hbrBackground: hbrBackground,
        lpszMenuName: nil,
        lpszClassName: $0.baseAddress!,
        hIconSm: nil)
    }
  }

  public func register() -> Bool {
    guard atom == nil else { return true }
    self.atom = RegisterClassExW(&value)
    return atom == nil ? false : true
  }

  public func unregister() -> Bool {
    if atom == nil { return true }
    if UnregisterClassW(self.name, self.hInstance) {
      self.atom = nil
    }
    return self.atom == nil
  }
}
