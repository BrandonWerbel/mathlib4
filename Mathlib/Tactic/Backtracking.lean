/-
Copyright (c) 2023 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import Lean.Meta.Basic

/-!
# `backtracking`

A meta-tactic for running backtracking search, given a non-deterministic tactic
`alternatives : MVarId → MetaM (List (MetaM (List MVarId)))`.

Here the outermost list gives us alternative solutions to the input goal.
The innermost list is then the new subgoals generated in that solution.
The additional `MetaM` allows for deferring computation.

`backtrack alternatives goals` will recursively try to solve all goals in `goals`,
and the subgoals generated, backtracking as necessary.

In its default behaviour, it will either solve all goals, or fail.
A customisable `suspend` hook in `BacktrackConfig` allows suspend a goal (or subgoal),
so that it will be returned instead of processed further.
Other hooks `proc` and `discharge` (described in `BacktrackConfig`) allow running other
tactics before `alternatives`, or if all search branches from a given goal fail.

See also `nondeterministic`, an alternative implementation of the same idea,
but with simpler flow control, and no trace messages.

Currently only `solveByElim` is implemented in terms of `backtrack`.
-/

open Lean

/-- Visualize an `Except` using a checkmark or a cross. -/
def Except.emoji : Except ε α → String
  | .error _ => crossEmoji
  | .ok _ => checkEmoji

namespace Lean.MVarId

/--
Given any tactic that takes a goal, and returns a sequence of alternative outcomes
(each outcome consisting of a list of new subgoals),
we can perform backtracking search by repeatedly applying the tactic.
-/
def firstContinuation (results : MVarId → MetaM (List (MetaM (List MVarId))))
    (cont : List MVarId → MetaM α) (g : MVarId) : MetaM α := do
  (← results g).firstM fun r => do cont (← r)

end Lean.MVarId

namespace Mathlib.Tactic

/--
Configuration structure to control the behaviour of `backtrack`:
* control the maximum depth and behaviour (fail or return subgoals) at the maximum depth,
* and hooks allowing
  * modifying intermediate goals before running the external tactic,
  * 'suspending' goals, returning them in the result, and
  * discharging subgoals if the external tactic fails.
-/
structure BacktrackConfig where
  /-- Maximum recursion depth. -/
  maxDepth : Nat := 6
  /-- If `failAtMaxDepth`, then `backtracking` will fail (and backtrack)
  upon reaching the max depth. Otherwise, upon reaching the max depth,
  all remaining goals will be returned.
  (defaults to `true`) -/
  failAtMaxDepth : Bool := true
  /-- An arbitrary procedure which can be used to modify the list of goals
  before each attempt to apply a lemma.
  Called as `proc goals curr`, where `goals` are the original goals for `backtracking`,
  and `curr` are the current goals.
  Returning `some l` will replace the current goals with `l` and recurse
  (consuming one step of maximum depth).
  Returning `none` will proceed to applying lemmas without changing goals.
  Failure will cause backtracking.
  (defaults to `none`) -/
  proc : List MVarId → List MVarId → MetaM (Option (List MVarId)) := fun _ _ => pure none
  /-- If `suspend g`, then we do not attempt to apply any further lemmas,
  but return `g` as a new subgoal. (defaults to `false`) -/
  suspend : MVarId → MetaM Bool := fun _ => pure false
  /-- `discharge g` is called on goals for which no lemmas apply.
  If `none` we return `g` as a new subgoal.
  If `some l`, we replace `g` by `l` in the list of active goals, and recurse.
  If failure, we backtrack. (defaults to failure) -/
  discharge : MVarId → MetaM (Option (List MVarId)) := fun _ => failure

/--
Attempts to solve the `goals`, by recursively calling `alternatives g` on each subgoal that appears.
`alternatives` returns a list of list of goals (wrapped in `MetaM`).
The outermost list corresponds to alternative outcomes,
while the innermost list is the subgoals generated in that outcome.

`backtrack` performs a backtracking search, attempting to close all subgoals.

Further flow control options are available via the `Config` argument.
-/
def backtrack (cfg : BacktrackConfig := {}) (trace : Name := .anonymous)
    (alternatives : MVarId → MetaM (List (MetaM (List MVarId))))
    (goals : List MVarId) : MetaM (List MVarId) := do
run cfg.maxDepth goals []
  where
  /--
  * `n : Nat` steps remaining.
  * `curr : List MVarId` the current list of unsolved goals.
  * `acc : List MVarId` a list of "suspended" goals, which will be returned as subgoals.
  -/
  -- `acc` is intentionally a `List` rather than an `Array` so we can share across branches.
  run (n : Nat) (curr acc : List MVarId) : MetaM (List MVarId) := do
  match n with
  | 0 => do
    -- We're out of fuel.
    if cfg.failAtMaxDepth then
      throwError "backtrack exceeded the recursion limit"
    else
      -- Before returning the goals, we run `cfg.proc` one last time.
      let curr := acc.reverse ++ curr
      return (← cfg.proc goals curr).getD curr
  | n + 1 => do
  -- First, run `cfg.proc`, to see if it wants to modify the goals.
  match ← cfg.proc goals curr with
  | some curr' => run n curr' acc
  | none =>
  match curr with
  -- If there are no active goals, return the accumulated goals.
  | [] => return acc.reverse
  | g :: gs =>
  -- Discard any goals which have already been assigned.
  if ← g.isAssigned then
    run (n+1) gs acc
  else
  withTraceNode trace
    -- Note: the `addMessageContextFull` ensures we show the goal using the mvar context before
    -- the `do` block below runs, potentially unifying mvars in the goal.
    (return m!"{·.emoji} working on: {← addMessageContextFull g}")
    do
      -- Check if we should suspend the search here:
      if (← cfg.suspend g) then
        withTraceNode trace
          (fun _ => return m!"⏸️ suspending search and returning as subgoal") do
        run (n+1) gs (g :: acc)
      else
        try
          -- We attempt to find an expression which can be applied,
          -- and for which all resulting sub-goals can be discharged using `run n`.
          g.firstContinuation alternatives (fun res => run n (res ++ gs) acc)
        catch _ =>
          -- No lemmas could be applied:
          match (← cfg.discharge g) with
          | none => (withTraceNode trace
              (fun _ => return m!"⏭️ deemed acceptable, returning as subgoal") do
            run (n+1) gs (g :: acc))
          | some l => (withTraceNode trace
              (fun _ => return m!"⏬ discharger generated new subgoals") do
            run n (l ++ gs) acc)
  termination_by run n curr acc => (n, curr)

end Mathlib.Tactic
