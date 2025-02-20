/-
Copyright (c) 2022 Yury Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury Kudryashov

! This file was ported from Lean 3 source module algebra.order.positive.field
! leanprover-community/mathlib commit bbeb185db4ccee8ed07dc48449414ebfa39cb821
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Algebra.Order.Positive.Ring

/-!
# Algebraic structures on the set of positive numbers

In this file we prove that the set of positive elements of a linear ordered field is a linear
ordered commutative group.
-/


variable {K : Type _} [LinearOrderedField K]

namespace Positive

instance Subtype.inv : Inv { x : K // 0 < x } :=
  ⟨fun x => ⟨x⁻¹, inv_pos.2 x.2⟩⟩

@[simp]
theorem coe_inv (x : { x : K // 0 < x }) : ↑x⁻¹ = (x⁻¹ : K) :=
  rfl
#align positive.coe_inv Positive.coe_inv

instance : Pow { x : K // 0 < x } ℤ :=
  ⟨fun x n => ⟨(x: K) ^ n, zpow_pos_of_pos x.2 _⟩⟩

@[simp]
theorem coe_zpow (x : { x : K // 0 < x }) (n : ℤ) : ↑(x ^ n) = (x : K) ^ n :=
  rfl
#align positive.coe_zpow Positive.coe_zpow

-- porting notes: required to create the instance below
set_option maxHeartbeats 304000
instance : LinearOrderedCommGroup { x : K // 0 < x } :=
  { Positive.Subtype.inv, Positive.linearOrderedCancelCommMonoid with
    mul_left_inv := fun a => Subtype.ext <| inv_mul_cancel a.2.ne' }

end Positive
