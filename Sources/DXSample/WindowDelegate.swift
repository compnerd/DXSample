// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import WinSDK

public protocol WindowDelegate: AnyObject {
  func close() -> LRESULT
  func render() throws
  func resize(width: Int, height: Int) throws
  func update()
  func mouse(movedTo x: WORD, _ y: WORD, virtualKeyPress: WORD)
}

extension WindowDelegate {
  public func close() -> LRESULT {
    PostQuitMessage(0)
    return 0
  }

  public func resize(width: Int, height: Int) throws {
  }

  public func mouse(movedTo x: WORD, _ y: WORD, virtualKeyPress: WORD) {
  }
}
