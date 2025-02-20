/-
Copyright (c) 2019 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Johan Commelin

! This file was ported from Lean 3 source module ring_theory.free_ring
! leanprover-community/mathlib commit d6814c584384ddf2825ff038e868451a7c956f31
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.GroupTheory.FreeAbelianGroup

/-!
# Free rings

The theory of the free ring over a type.

## Main definitions

* `FreeRing α` : the free (not commutative in general) ring over a type.
* `lift (f : α → R)` : the ring hom `FreeRing α →+* R` induced by `f`.
* `map (f : α → β)` : the ring hom `FreeRing α →+* FreeRing β` induced by `f`.

## Implementation details

`FreeRing α` is implemented as the free abelian group over the free monoid on `α`.

## Tags

free ring

-/


universe u v

/-- The free ring over a type `α`. -/
def FreeRing (α : Type u) : Type u :=
  FreeAbelianGroup <| FreeMonoid α
#align free_ring FreeRing

instance (α : Type u) : Ring (FreeRing α) :=
  FreeAbelianGroup.ring _

instance (α : Type u) : Inhabited (FreeRing α) := by
  dsimp only [FreeRing]
  infer_instance

namespace FreeRing

variable {α : Type u}

/-- The canonical map from α to `FreeRring α`. -/
def of (x : α) : FreeRing α :=
  FreeAbelianGroup.of (FreeMonoid.of x)
#align free_ring.of FreeRing.of

theorem of_injective : Function.Injective (of : α → FreeRing α) :=
  FreeAbelianGroup.of_injective.comp FreeMonoid.of_injective
#align free_ring.of_injective FreeRing.of_injective

@[elab_as_elim]
protected theorem induction_on {C : FreeRing α → Prop} (z : FreeRing α) (hn1 : C (-1))
    (hb : ∀ b, C (of b)) (ha : ∀ x y, C x → C y → C (x + y)) (hm : ∀ x y, C x → C y → C (x * y)) :
    C z :=
  have hn : ∀ x, C x → C (-x) := fun x ih => neg_one_mul x ▸ hm _ _ hn1 ih
  have h1 : C 1 := neg_neg (1 : FreeRing α) ▸ hn _ hn1
  FreeAbelianGroup.induction_on z (add_left_neg (1 : FreeRing α) ▸ ha _ _ hn1 h1)
    (fun m => List.recOn m h1 fun a m ih => by
      -- porting note: in mathlib, convert was not necessary, `exact hm _ _ (hb a) ih` worked fine
      convert hm _ _ (hb a) ih
      rw [of, ← FreeAbelianGroup.of_mul]
      rfl)
    (fun m ih => hn _ ih) ha
#align free_ring.induction_on FreeRing.induction_on

section lift

variable {R : Type v} [Ring R] (f : α → R)

/-- The ring homomorphism `FreeRing α →+* R` induced from a map `α → R`. -/
def lift : (α → R) ≃ (FreeRing α →+* R) :=
  FreeMonoid.lift.trans FreeAbelianGroup.liftMonoid
#align free_ring.lift FreeRing.lift

@[simp]
theorem lift_of (x : α) : lift f (of x) = f x :=
  congr_fun (lift.left_inv f) x
#align free_ring.lift_of FreeRing.lift_of

@[simp]
theorem lift_comp_of (f : FreeRing α →+* R) : lift (f ∘ of) = f :=
  lift.right_inv f
#align free_ring.lift_comp_of FreeRing.lift_comp_of

@[ext]
theorem hom_ext ⦃f g : FreeRing α →+* R⦄ (h : ∀ x, f (of x) = g (of x)) : f = g :=
  lift.symm.injective (funext h)
#align free_ring.hom_ext FreeRing.hom_ext

end lift

variable {β : Type v} (f : α → β)

/-- The canonical ring homomorphism `FreeRing α →+* FreeRing β` generated by a map `α → β`. -/
def map : FreeRing α →+* FreeRing β :=
  lift <| of ∘ f
#align free_ring.map FreeRing.map

@[simp]
theorem map_of (x : α) : map f (of x) = of (f x) :=
  lift_of _ _
#align free_ring.map_of FreeRing.map_of

end FreeRing
