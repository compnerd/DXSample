// Copyright © 2021 Saleem Abdulrasool <compnerd@compnerd.org>.
// SPDX-License-Identifier: BSD-3

// Rewritten Swift variants of DirectX Math Routines.
// TODO(compnerd) these should be rewritten to be better for Swift.  However,
// this is a tactical implementation for the moment since we cannot import the
// DXMath routines as they are in C++.

import Foundation
import WinSDK

internal typealias FLOAT3 = (FLOAT, FLOAT, FLOAT)
internal typealias FLOAT4 = (FLOAT, FLOAT, FLOAT, FLOAT)
internal typealias FLOAT4X4 = (FLOAT4, FLOAT4, FLOAT4, FLOAT4)

internal var XM_1DIV2PI: FLOAT {
  0.159154943
}

internal var XM_2PI: FLOAT {
  6.283185307
}

internal var XM_PIDIV2: FLOAT {
  1.570796327
}

internal var XM_PIDIV4: FLOAT {
  0.785398163
}

internal var XM_PI: FLOAT {
  3.141592654
}

internal func XMScalarSinCos(_ pSin: inout FLOAT, _ pCos: inout FLOAT, _ Value: FLOAT) {
  // Map Value to y in [-pi,pi], x = 2*pi*quotient + remainder
  var quotient: FLOAT = XM_1DIV2PI * Value
  if Value >= 0.0 {
    quotient = FLOAT(Int32(quotient + 0.5))
  } else {
    quotient = FLOAT(Int32(quotient - 0.5))
  }
  var y: Float32 = Value - XM_2PI * quotient

  // Map y to [-pi/2,pi/2] with sin(y) = sin(Value).
  let sign: FLOAT
  if y > XM_PIDIV2 {
    y = XM_PI - y
    sign = -1.0
  } else {
    sign = 1.0
  }

  let y2: FLOAT = y * y

  // 7-degree minmax approximation
  pSin = (((-0.00018524670 * y2 + 0.0083139502) * y2 - 0.16665852) * y2 + 1.0) * y

  // 6-degree minmax approximation
  let p: FLOAT = ((-0.0012712436 * y2 + 0.041493919) * y2 - 0.49992746) * y2 + 1.0
  pCos = sign * p
}

internal func XMConvertToRadians(_ degrees: FLOAT) -> FLOAT {
  degrees * (.pi / 180.0)
}

internal func XMMatrixRotationX(_ angle: FLOAT) -> FLOAT4X4 {
  var SinAngle: FLOAT = 0
  var CosAngle: FLOAT = 0
  XMScalarSinCos(&SinAngle, &CosAngle, angle)

  return (
    (1.0, 0.0, 0.0, 0.0),
    (0.0, CosAngle, -SinAngle, 0.0),
    (0.0, SinAngle, CosAngle, 0.0),
    (0.0, 0.0, 0.0, 1.0)
  )
}

internal func XMMatrixRotationY(_ angle: FLOAT) -> FLOAT4X4 {
  var SinAngle: FLOAT = 0
  var CosAngle: FLOAT = 0
  XMScalarSinCos(&SinAngle, &CosAngle, angle)

  return (
    (CosAngle, 0.0, SinAngle, 0.0),
    (0.0, 1.0, 0.0, 0.0),
    (-SinAngle, 0.0, CosAngle, 0.0),
    (0.0, 0.0, 0.0, 1.0)
  )
}

internal func XMMatrixRotationZ(_ angle: FLOAT) -> FLOAT4X4 {
  var SinAngle: FLOAT = 0
  var CosAngle: FLOAT = 0
  XMScalarSinCos(&SinAngle, &CosAngle, angle)

  return (
    (CosAngle, -SinAngle, 0.0, 0.0),
    (SinAngle, CosAngle, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 1.0)
  )
}

internal func XMMatrixTranspose(_ m: FLOAT4X4) -> FLOAT4X4 {
  return (
    (m.0.0, m.1.0, m.2.0, m.3.0),
    (m.0.1, m.1.1, m.2.1, m.3.1),
    (m.0.2, m.1.2, m.2.2, m.3.2),
    (m.0.3, m.1.3, m.2.3, m.3.3)
  )
}

internal func XMVectorNegate(_ v: FLOAT4) -> FLOAT4 {
  return (-v.0, -v.1, -v.2, -v.3)
}

internal func XMMatrixLookToLH(_ position: FLOAT4, _ direction: FLOAT4, _ up: FLOAT4) -> FLOAT4X4 {
  let r2: FLOAT4 = XMVectorNormalize(direction)

  let r0: FLOAT4 = XMVectorNormalize(up * r2)

  let r1: FLOAT4 = r2 * r0

  let negPos: FLOAT4 = XMVectorNegate(position)

  let d0: FLOAT = r0 * negPos
  let d1: FLOAT = r1 * negPos
  let d2: FLOAT = r2 * negPos

  let m: FLOAT4X4 = (
    (r0.0, r0.1, r0.2, d0),
    (r1.0, r1.1, r1.2, d1),
    (r2.0, r2.1, r2.2, d2),
    (0.0, 0.0, 0.0, 1.0)
  )

  return XMMatrixTranspose(m)
}

internal func XMMatrixLookAtLH(_ position: FLOAT4, _ target: FLOAT4, _ up: FLOAT4) -> FLOAT4X4 {
  let direction = target - position
  return XMMatrixLookToLH(position, direction, up)
}

internal func XMMatrixPerspectiveFovLH(_ fov: FLOAT, _ aspect: FLOAT, _ near: FLOAT, _ far: FLOAT)
  -> FLOAT4X4
{
  var SinFov: FLOAT = 0.0
  var CosFov: FLOAT = 0.0
  XMScalarSinCos(&SinFov, &CosFov, 0.5 * fov)

  let height = CosFov / SinFov
  let width = height / aspect
  let range = far / (far - near)

  return (
    (width, 0.0, 0.0, 0.0),
    (0.0, height, 0.0, 0.0),
    (0.0, 0.0, range, 1.0),
    (0.0, 0.0, -range * near, 0.0)
  )
}

// Since FLOAT4 is a non-nomimal type just create a custom decoration for the
// name.
internal var FLOAT4_zero: FLOAT4 = (
  0.0, 0.0, 0.0, 0.0
)

// Since FLOAT4X4 is a non-nominal type just create a custom decoration for the
// name.
internal var FLOAT4X4_identity: FLOAT4X4 = (
  FLOAT4(1.0, 0.0, 0.0, 0.0),
  FLOAT4(0.0, 1.0, 0.0, 0.0),
  FLOAT4(0.0, 0.0, 1.0, 0.0),
  FLOAT4(0.0, 0.0, 0.0, 1.0)
)

internal func * (_ lhs: FLOAT4X4, _ rhs: FLOAT4X4) -> FLOAT4X4 {
  let _00 = lhs.0.0 * rhs.0.0 + lhs.0.1 * rhs.1.0 + lhs.0.2 * rhs.2.0 + lhs.0.3 * rhs.3.0
  let _01 = lhs.0.0 * rhs.0.1 + lhs.0.1 * rhs.1.1 + lhs.0.2 * rhs.2.1 + lhs.0.3 * rhs.3.1
  let _02 = lhs.0.0 * rhs.0.2 + lhs.0.1 * rhs.1.2 + lhs.0.2 * rhs.2.2 + lhs.0.3 * rhs.3.2
  let _03 = lhs.0.0 * rhs.0.3 + lhs.0.1 * rhs.1.3 + lhs.0.2 * rhs.2.3 + lhs.0.3 * rhs.3.3

  let _10 = lhs.1.0 * rhs.0.0 + lhs.1.1 * rhs.1.0 + lhs.1.2 * rhs.2.0 + lhs.1.3 * rhs.3.0
  let _11 = lhs.1.0 * rhs.0.1 + lhs.1.1 * rhs.1.1 + lhs.1.2 * rhs.2.1 + lhs.1.3 * rhs.3.1
  let _12 = lhs.1.0 * rhs.0.2 + lhs.1.1 * rhs.1.2 + lhs.1.2 * rhs.2.2 + lhs.1.3 * rhs.3.2
  let _13 = lhs.1.0 * rhs.0.3 + lhs.1.1 * rhs.1.3 + lhs.1.2 * rhs.2.3 + lhs.1.3 * rhs.3.3

  let _20 = lhs.2.0 * rhs.0.0 + lhs.2.1 * rhs.1.0 + lhs.2.2 * rhs.2.0 + lhs.2.3 * rhs.3.0
  let _21 = lhs.2.0 * rhs.0.1 + lhs.2.1 * rhs.1.1 + lhs.2.2 * rhs.2.1 + lhs.2.3 * rhs.3.1
  let _22 = lhs.2.0 * rhs.0.2 + lhs.2.1 * rhs.1.2 + lhs.2.2 * rhs.2.2 + lhs.2.3 * rhs.3.2
  let _23 = lhs.2.0 * rhs.0.3 + lhs.2.1 * rhs.1.3 + lhs.2.2 * rhs.2.3 + lhs.2.3 * rhs.3.3

  let _30 = lhs.3.0 * rhs.0.0 + lhs.3.1 * rhs.1.0 + lhs.3.2 * rhs.2.0 + lhs.3.3 * rhs.3.0
  let _31 = lhs.3.0 * rhs.0.1 + lhs.3.1 * rhs.1.1 + lhs.3.2 * rhs.2.1 + lhs.3.3 * rhs.3.1
  let _32 = lhs.3.0 * rhs.0.2 + lhs.3.1 * rhs.1.2 + lhs.3.2 * rhs.2.2 + lhs.3.3 * rhs.3.2
  let _33 = lhs.3.0 * rhs.0.3 + lhs.3.1 * rhs.1.3 + lhs.3.2 * rhs.2.3 + lhs.3.3 * rhs.3.3

  return (
    (_00, _01, _02, _03),
    (_10, _11, _12, _13),
    (_20, _21, _22, _23),
    (_30, _31, _32, _33)
  )
}

internal func * (_ lhs: FLOAT4, _ rhs: FLOAT4) -> FLOAT4 {
  // lhs.y * rhs.z - lhs.z * rhs.y, lhs.z * rhsrhs.x - lhs.x * rhs.z, lhs.x * rhs.y - lhs.y * rhs.x
  return (
    (lhs.1 * rhs.2) - (lhs.2 * rhs.1),
    (lhs.2 * rhs.0) - (lhs.0 * rhs.2),
    (lhs.0 * rhs.1) - (lhs.1 * rhs.0),
    0.0
  )
}

internal func * (_ lhs: FLOAT4, _ rhs: FLOAT4) -> FLOAT {
  return lhs.0 * rhs.0 + lhs.1 * rhs.1 + lhs.2 * rhs.2 + lhs.3 * rhs.3
}

internal func - (_ lhs: FLOAT4, _ rhs: FLOAT4) -> FLOAT4 {
  return (lhs.0 - rhs.0, lhs.1 - rhs.1, lhs.2 - rhs.2, lhs.3 - rhs.3)
}

internal func XMVectorNormalize(_ v: FLOAT4) -> FLOAT4 {
  var length = sqrt(v * v as FLOAT)
  if length > 0 { length = 1.0 / length }

  return (
    v.0 * length,
    v.1 * length,
    v.2 * length,
    v.3 * length
  )
}
