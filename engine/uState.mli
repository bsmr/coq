(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2015     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(** This file defines universe unification states which are part of evarmaps.
    Most of the API below is reexported in {!Evd}. Consider using higher-level
    primitives when needed. *)

open Names

exception UniversesDiffer

type t
(** Type of universe unification states. They allow the incremental building of
    universe constraints during an interactive proof. *)

(** {5 Constructors} *)

val empty : t

val make : UGraph.t -> t

val is_empty : t -> bool

val union : t -> t -> t

val of_context_set : Univ.ContextSet.t -> t

val of_binders : Universes.universe_binders -> t

val universe_binders : t -> Universes.universe_binders

(** {5 Projections} *)

val context_set : t -> Univ.ContextSet.t
(** The local context of the state, i.e. a set of bound variables together
    with their associated constraints. *)

val subst : t -> Universes.universe_opt_subst
(** The local universes that are unification variables *)

val ugraph : t -> UGraph.t
(** The current graph extended with the local constraints *)

val initial_graph : t -> UGraph.t
(** The initial graph with just the declarations of new universes. *)

val algebraics : t -> Univ.LSet.t
(** The subset of unification variables that can be instantiated with algebraic
    universes as they appear in inferred types only. *)

val constraints : t -> Univ.constraints
(** Shorthand for {!context_set} composed with {!ContextSet.constraints}. *)

val context : t -> Univ.UContext.t
(** Shorthand for {!context_set} with {!Context_set.to_context}. *)

val const_univ_entry : poly:bool -> t -> Entries.constant_universes_entry
(** Pick from {!context} or {!context_set} based on [poly]. *)

val ind_univ_entry : poly:bool -> t -> Entries.inductive_universes
(** Pick from {!context} or {!context_set} based on [poly].
    Cannot create cumulative entries. *)

(** {5 Constraints handling} *)

val add_constraints : t -> Univ.constraints -> t
(**
  @raise UniversesDiffer when universes differ
*)

val add_universe_constraints : t -> Universes.universe_constraints -> t
(**
  @raise UniversesDiffer when universes differ
*)

(** {5 Names} *)

val universe_of_name : t -> Id.t -> Univ.Level.t
(** Retrieve the universe associated to the name. *)

(** {5 Unification} *)

val restrict : t -> Univ.LSet.t -> t

type rigid = 
  | UnivRigid
  | UnivFlexible of bool (** Is substitution by an algebraic ok? *)

val univ_rigid : rigid
val univ_flexible : rigid
val univ_flexible_alg : rigid

val merge : ?loc:Loc.t -> bool -> rigid -> t -> Univ.ContextSet.t -> t
val merge_subst : t -> Universes.universe_opt_subst -> t
val emit_side_effects : Safe_typing.private_constants -> t -> t

val new_univ_variable : ?loc:Loc.t -> rigid -> Id.t option -> t -> t * Univ.Level.t
val add_global_univ : t -> Univ.Level.t -> t

(** [make_flexible_variable g algebraic l]

  Turn the variable [l] flexible, and algebraic if [algebraic] is true
  and [l] can be. That is if there are no strict upper constraints on
  [l] and and it does not appear in the instance of any non-algebraic
  universe. Otherwise the variable is just made flexible. *)
val make_flexible_variable : t -> algebraic:bool -> Univ.Level.t -> t

(** Turn all undefined flexible algebraic variables into simply flexible
   ones. Can be used in case the variables might appear in universe instances
   (typically for polymorphic program obligations). *)
val make_flexible_nonalgebraic : t -> t

val is_sort_variable : t -> Sorts.t -> Univ.Level.t option

val normalize_variables : t -> Univ.universe_subst * t

val constrain_variables : Univ.LSet.t -> t -> t

val abstract_undefined_variables : t -> t

val fix_undefined_variables : t -> t

val refresh_undefined_univ_variables : t -> t * Univ.universe_level_subst

val normalize : t -> t

type universe_decl =
  (Names.Id.t Loc.located list, Univ.Constraint.t) Misctypes.gen_universe_decl

(** [check_univ_decl ctx decl]

   If non extensible in [decl], check that the local universes (resp.
   universe constraints) in [ctx] are implied by [decl].

   Return a [Entries.constant_universes_entry] containing the local
   universes of [ctx] and their constraints.

   When polymorphic, the universes corresponding to
   [decl.univdecl_instance] come first in the order defined by that
   list. *)
val check_univ_decl : poly:bool -> t -> universe_decl -> Entries.constant_universes_entry

val check_mono_univ_decl : t -> universe_decl -> Univ.ContextSet.t

(** {5 TODO: Document me} *)

val update_sigma_env : t -> Environ.env -> t

(** {5 Pretty-printing} *)

val pr_uctx_level : t -> Univ.Level.t -> Pp.t
