/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies

! This file was ported from Lean 3 source module data.pnat.interval
! leanprover-community/mathlib commit f7fc89d5d5ff1db2d1242c7bb0e9062ce47ef47c
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Data.Nat.Interval
import Mathlib.Data.PNat.Defs

/-!
# Finite intervals of positive naturals

This file proves that `ℕ+` is a `LocallyFiniteOrder` and calculates the cardinality of its
intervals as finsets and fintypes.
-/


open Finset PNat

instance : LocallyFiniteOrder ℕ+ :=
  instLocallyFiniteOrderSubtypePreorder _

namespace PNat

variable (a b : ℕ+)

theorem Icc_eq_finset_subtype : Icc a b = (Icc (a : ℕ) b).subtype fun n : ℕ => 0 < n :=
  rfl
#align pnat.Icc_eq_finset_subtype PNat.Icc_eq_finset_subtype

theorem Ico_eq_finset_subtype : Ico a b = (Ico (a : ℕ) b).subtype fun n : ℕ => 0 < n :=
  rfl
#align pnat.Ico_eq_finset_subtype PNat.Ico_eq_finset_subtype

theorem Ioc_eq_finset_subtype : Ioc a b = (Ioc (a : ℕ) b).subtype fun n : ℕ => 0 < n :=
  rfl
#align pnat.Ioc_eq_finset_subtype PNat.Ioc_eq_finset_subtype

theorem Ioo_eq_finset_subtype : Ioo a b = (Ioo (a : ℕ) b).subtype fun n : ℕ => 0 < n :=
  rfl
#align pnat.Ioo_eq_finset_subtype PNat.Ioo_eq_finset_subtype

theorem map_subtype_embedding_Icc : (Icc a b).map (Function.Embedding.subtype _) = Icc (a : ℕ) b :=
  Finset.map_subtype_embedding_Icc _ _ _ fun _c _ _x hx _ hc _ => hc.trans_le hx
#align pnat.map_subtype_embedding_Icc PNat.map_subtype_embedding_Icc

theorem map_subtype_embedding_Ico : (Ico a b).map (Function.Embedding.subtype _) = Ico (a : ℕ) b :=
  Finset.map_subtype_embedding_Ico _ _ _ fun _c _ _x hx _ hc _ => hc.trans_le hx
#align pnat.map_subtype_embedding_Ico PNat.map_subtype_embedding_Ico

theorem map_subtype_embedding_Ioc : (Ioc a b).map (Function.Embedding.subtype _) = Ioc (a : ℕ) b :=
  Finset.map_subtype_embedding_Ioc _ _ _ fun _c _ _x hx _ hc _ => hc.trans_le hx
#align pnat.map_subtype_embedding_Ioc PNat.map_subtype_embedding_Ioc

theorem map_subtype_embedding_Ioo : (Ioo a b).map (Function.Embedding.subtype _) = Ioo (a : ℕ) b :=
  Finset.map_subtype_embedding_Ioo _ _ _ fun _c _ _x hx _ hc _ => hc.trans_le hx
#align pnat.map_subtype_embedding_Ioo PNat.map_subtype_embedding_Ioo

@[simp]
theorem card_Icc : (Icc a b).card = b + 1 - a := by
  rw [← Nat.card_Icc]
  erw [← Finset.map_subtype_embedding_Icc _ a b (fun c x _ hx _ hc _ => hc.trans_le hx)]
  -- porting note: I had to change this to `erw` *and* provide the proof, yuck.
  rw [card_map]
#align pnat.card_Icc PNat.card_Icc

@[simp]
theorem card_Ico : (Ico a b).card = b - a := by
  rw [← Nat.card_Ico]
  erw [← Finset.map_subtype_embedding_Ico _ a b (fun c x _ hx _ hc _ => hc.trans_le hx)]
  -- porting note: I had to change this to `erw` *and* provide the proof, yuck.
  rw  [card_map]
#align pnat.card_Ico PNat.card_Ico

@[simp]
theorem card_Ioc : (Ioc a b).card = b - a := by
  rw [← Nat.card_Ioc]
  erw [← Finset.map_subtype_embedding_Ioc _ a b (fun c x _ hx _ hc _ => hc.trans_le hx)]
  -- porting note: I had to change this to `erw` *and* provide the proof, yuck.
  rw  [card_map]
#align pnat.card_Ioc PNat.card_Ioc

@[simp]
theorem card_Ioo : (Ioo a b).card = b - a - 1 := by
  rw [← Nat.card_Ioo]
  erw [← Finset.map_subtype_embedding_Ioo _ a b (fun c x _ hx _ hc _ => hc.trans_le hx)]
  -- porting note: I had to change this to `erw` *and* provide the proof, yuck.
  rw  [card_map]
#align pnat.card_Ioo PNat.card_Ioo

-- porting note: `simpNF` says `simp` can prove this
theorem card_fintype_Icc : Fintype.card (Set.Icc a b) = b + 1 - a := by
  rw [← card_Icc, Fintype.card_ofFinset]
#align pnat.card_fintype_Icc PNat.card_fintype_Icc

-- porting note: `simpNF` says `simp` can prove this
theorem card_fintype_Ico : Fintype.card (Set.Ico a b) = b - a := by
  rw [← card_Ico, Fintype.card_ofFinset]
#align pnat.card_fintype_Ico PNat.card_fintype_Ico

-- porting note: `simpNF` says `simp` can prove this
theorem card_fintype_Ioc : Fintype.card (Set.Ioc a b) = b - a := by
  rw [← card_Ioc, Fintype.card_ofFinset]
#align pnat.card_fintype_Ioc PNat.card_fintype_Ioc

-- porting note: `simpNF` says `simp` can prove this
theorem card_fintype_Ioo : Fintype.card (Set.Ioo a b) = b - a - 1 := by
  rw [← card_Ioo, Fintype.card_ofFinset]
#align pnat.card_fintype_Ioo PNat.card_fintype_Ioo

end PNat
