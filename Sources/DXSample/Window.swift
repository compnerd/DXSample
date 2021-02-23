// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import SwiftCOM

import WinSDK

private func WindowProcedure(
  _ hWnd: HWND?, _ uMsg: UINT, _ wParam: WPARAM,
  _ lParam: LPARAM
) -> LRESULT {
  let lpUserData = GetWindowLongPtrW(hWnd, GWLP_USERDATA)
  if lpUserData == 0 { return DefWindowProcW(hWnd, uMsg, wParam, lParam) }

  if let window = unsafeBitCast(lpUserData, to: AnyObject.self) as? Window {
    switch uMsg {
    case UINT(WM_SIZE):
      var rc: RECT = RECT()
      _ = GetClientRect(hWnd, &rc)

      try! window.delegate?.resize(
        width: Int(rc.right - rc.left),
        height: Int(rc.bottom - rc.top))

      return 0

    case UINT(WM_PAINT):
      if let pWindow: Window =
        unsafeBitCast(lpUserData, to: AnyObject.self) as? Window
      {
        pWindow.delegate?.update()
        try! pWindow.delegate?.render()
      }
      return 0

    case UINT(WM_MOUSEMOVE):
      if let pWindow: Window =
        unsafeBitCast(lpUserData, to: AnyObject.self) as? Window
      {
        pWindow.delegate?.mouse(
          movedTo: GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam),
          virtualKeyPress: WORD(wParam))
        try! pWindow.delegate?.render()
      }
      return 0

    case UINT(WM_KEYDOWN):
      switch wParam {
      case WPARAM(VK_ESCAPE):
        PostMessageW(hWnd, UINT(WM_DESTROY), 0, 0)
        return 0

      default: break
      }

    case UINT(WM_CLOSE):
      if let delegate = window.delegate {
        return delegate.close()
      }
      break

    case UINT(WM_DESTROY):
      PostQuitMessage(0)
      return 0

    default: break
    }
  }
  return DefWindowProcW(hWnd, uMsg, wParam, lParam)
}

public class Window {
  private static let `class`: WindowClass =
    WindowClass(
      hInst: GetModuleHandleW(nil), name: "DirectSwift.Window",
      WindowProc: WindowProcedure,
      style: DWORD(CS_HREDRAW | CS_VREDRAW),
      hCursor: LoadCursorW(nil, IDC_ARROW))

  public private(set) var hWnd: HWND!
  public weak var delegate: WindowDelegate?

  public var title: String? {
    get {
      let szLength: Int32 = GetWindowTextLengthW(self.hWnd)
      let buffer: [WCHAR] = [WCHAR](unsafeUninitializedCapacity: Int(szLength) + 1) {
        $1 = Int(GetWindowTextW(self.hWnd, $0.baseAddress, CInt($0.count)))
      }
      return String(decodingCString: buffer, as: UTF16.self)
    }
    set {
      _ = SetWindowTextW(self.hWnd, newValue?.wide)
    }
  }

  public var height: Int {
    var rc: RECT = RECT()
    _ = GetClientRect(self.hWnd, &rc)
    return Int(rc.bottom - rc.top)
  }

  public var width: Int {
    var rc: RECT = RECT()
    _ = GetClientRect(self.hWnd, &rc)
    return Int(rc.right - rc.left)
  }

  public init(_ title: String?, _ width: Int, _ height: Int) {
    _ = Self.class.register()

    // Create the client area rectangle, centering it on the screen.
    var rc: RECT = RECT()
    _ = SetRect(&rc, 0, 0, CLong(width), CLong(height))
    _ = AdjustWindowRect(&rc, DWORD(WS_OVERLAPPEDWINDOW), /*bMenu=*/ false)

    let dwWidth: CInt = rc.right - rc.left
    let dwHeight: CInt = rc.bottom - rc.top

    let dwScreenWidth: CInt = GetSystemMetrics(SM_CXSCREEN)
    let dwScreenHeight: CInt = GetSystemMetrics(SM_CYSCREEN)

    let dwTop: CInt = max(0, (dwScreenHeight - dwHeight) / 2)
    let dwLeft: CInt = max(0, (dwScreenWidth - dwWidth) / 2)

    // NOTE: force-unwrap to ensure that we have a valid Window
    self.hWnd = CreateWindowExW(
      0, Self.class.name, title?.wide,
      DWORD(WS_OVERLAPPEDWINDOW),
      dwLeft, dwTop, dwWidth, dwHeight,
      nil, nil, GetModuleHandleW(nil), nil)!

    _ = SetWindowLongPtrW(
      self.hWnd, GWLP_USERDATA,
      unsafeBitCast(self as AnyObject, to: LONG_PTR.self))
  }

  deinit {
    _ = DestroyWindow(hWnd)
    _ = Self.class.unregister()
  }
}
