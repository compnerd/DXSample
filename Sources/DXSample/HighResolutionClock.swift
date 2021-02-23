// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

import WinSDK

extension FILETIME {
  fileprivate var nanoseconds: UInt64 {
    // 100ns units; epoch: January 1, 1601 (UTC)
    (UInt64(self.dwHighDateTime) << 32 | UInt64(self.dwLowDateTime)) * 100
  }
}

public struct HighResolutionClock {
  private var ΔTime: UInt64 = 0
  private var ΣTime: UInt64 = 0

  private var t₀: FILETIME

  public struct TimeDelta {
    public let nanoseconds: UInt64

    public var microseconds: UInt64 { return nanoseconds / 1_000 }
    public var milliseconds: UInt64 { return nanoseconds / 1_000_000 }
    public var seconds: UInt64 { return nanoseconds / 1_000_000_000 }

    fileprivate init(nanoseconds: UInt64) {
      self.nanoseconds = nanoseconds
    }
  }

  public var delta: TimeDelta {
    TimeDelta(nanoseconds: self.ΔTime)
  }

  public var sigma: TimeDelta {
    TimeDelta(nanoseconds: ΣTime)
  }

  public init() {
    self.t₀ = FILETIME()
    GetSystemTimePreciseAsFileTime(&self.t₀)
  }

  public mutating func tick() {
    var t₁: FILETIME = FILETIME()
    GetSystemTimePreciseAsFileTime(&t₁)
    self.ΔTime = t₁.nanoseconds - self.t₀.nanoseconds
    self.ΣTime += self.ΔTime
    self.t₀ = t₁
  }

  public mutating func reset() {
    self.ΔTime = 0
    self.ΣTime = 0
    GetSystemTimePreciseAsFileTime(&self.t₀)
  }
}
