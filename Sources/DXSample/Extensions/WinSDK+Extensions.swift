// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import WinSDK

@_transparent
internal var IDC_ARROW: UnsafePointer<WCHAR> {
  UnsafePointer<WCHAR>(bitPattern: 32512)!
}

@_transparent
internal var HWND_TOPMOST: HWND {
  HWND(bitPattern: -1)!
}

@_transparent
internal var HWND_NOTOPMOST: HWND {
  HWND(bitPattern: -2)!
}

@_transparent
internal var E_FAIL: HRESULT {
  HRESULT(bitPattern: 0x80004005)
}

@_transparent
internal func LOWORD<T: BinaryInteger>(_ w: T) -> WORD {
  WORD((DWORD_PTR(w) >> 0) & 0xffff)
}

@_transparent
internal func HIWORD<T: BinaryInteger>(_ w: T) -> WORD {
  WORD((DWORD_PTR(w) >> 16) & 0xffff)
}

@_transparent
internal func GET_X_LPARAM(_ lParam: LPARAM) -> WORD {
  WORD(SHORT(LOWORD(lParam)))
}

@_transparent
internal func GET_Y_LPARAM(_ lParam: LPARAM) -> WORD {
  WORD(SHORT(HIWORD(lParam)))
}

@_transparent
func FAILED(_ body: @autoclosure () -> HRESULT) -> Bool {
  let hr: HRESULT = body()
  return hr < 0
}

@_transparent
func SUCCEEDED(_ body: @autoclosure () -> HRESULT) -> Bool {
  let hr: HRESULT = body()
  return hr >= 0
}
