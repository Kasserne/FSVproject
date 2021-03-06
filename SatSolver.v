Require Import SAT.project_lib.

(* Exercise 2.1 *)
Inductive form :=
  | f_var : id -> form
  | f_true : form
  | f_false : form
  | f_and : form -> form -> form
  | f_or : form -> form -> form
  | f_impl : form -> form -> form
  | f_neg : form -> form.

(* Custom Notation *)
Declare Custom Entry sat.
Notation "<{ e }>" := e (e custom sat at level 99).
Notation "( x )" := x (in custom sat, x at level 99).
Notation "x" := x (in custom sat at level 0, x constr at level 0).
Notation "x -> y" := (f_impl x y) (in custom sat at level 70, right associativity).
Notation "x /\ y" := (f_and x y) (in custom sat at level 40, left associativity).
Notation "x \/ y" := (f_or x y) (in custom sat at level 50, left associativity).
Notation "~ x" := (f_neg x) (in custom sat at level 30).
Notation "'true'"  := true (at level 1).
Notation "'true'" := f_true (in custom sat at level 0).
Notation "'false'"  := false (at level 1).
Notation "'false'" := f_false (in custom sat at level 0).
Coercion f_var : id >-> form.

Definition x : id := (Id 0).
Definition y : id := (Id 1).
Definition z : id := (Id 2).
Local Hint Unfold x : core.
Local Hint Unfold y : core.
Local Hint Unfold z : core.

(* Exercise 2.2 *)
Definition twotwoone := <{(x \/ ~y) /\ (~x \/ y)}>.
Definition twotwotwo := <{ ~y -> (x \/ y) }> .
Definition twotwothree := <{ x /\ ~x /\ true }>.

Definition valuation := id -> bool .
Definition empty_valuation : valuation := fun x => false .
Definition override (V : valuation ) (x : id) (b : bool ) : valuation :=
  fun y => if beq_id x y then b else V y.

(* Exercise 2.3 *)
Fixpoint interp (V : valuation) (p : form ) : bool :=
  match p with
  | f_true => true
  | f_false => false
  | f_var x => V x
  | <{ x /\ y }> => (interp V x) && (interp V y)
  | <{ x \/ y }> => (interp V x) || (interp V y)
  | <{ ~x }> => negb (interp V x)
  | <{ x -> y }> => negb (interp V x) || (interp V y)
  end.

Notation "'Ø'" := empty_valuation.
Notation "m '|[' x '|->' v ']|'" := (override m x v)  (at level 100, v at next level, right associativity).

(* A test valuation, assigning  x = false, y = true, z = true using the custom notation*)
Definition testval := Ø|[x |-> false]||[y |-> true]||[z |-> true]|.

Example interp_test1 : interp testval twotwoone = false. 
Proof. reflexivity. Qed.

Example interp_test2 : interp testval twotwotwo = true. 
Proof. reflexivity. Qed.

Example interp_test3 : interp testval twotwothree = false. 
Proof. reflexivity. Qed.

(* Satisfiability states that there exists some valuation, making the interpretation of the formular true *)
Definition satisfiable (p : form ) : Prop := exists V : valuation , interp V p = true.

(* Exercise 2.4 *)
Lemma test1 : satisfiable twotwoone .
Proof. 
  unfold satisfiable, twotwoone. exists Ø. reflexivity.
Qed.

Lemma test2 : satisfiable twotwotwo .
Proof.
  unfold satisfiable, twotwotwo. exists (Ø|[ x |-> true]|). reflexivity.
Qed.

(* Helper function to add an element to a list, only if the element
   is not already present within the list 
*)
Fixpoint set_add (x : id) (l : list id) :=
  match l with
  | nil => [x]
  | a :: l' => if beq_id a x then l else a :: (set_add x l')
  end.

(* Computes the union of two lists as if they were sets, 
   i.e. disallowing duplicate entries
*)
Fixpoint set_union (l1 l2 : list id) : list id :=
  match l1 with
  | nil => l2
  | x :: l' => set_add x (set_union l' l2)
  end.

(* Computes the list of id's present in a given formular p *)
Fixpoint occuring_vars (p : form) : list id :=
  match p with
  | f_true => nil
  | f_false => nil
  | f_var x => [x]
  | <{ x /\ y }> => set_union (occuring_vars x) (occuring_vars y)
  | <{ x \/ y }> => set_union (occuring_vars x) (occuring_vars y)
  | <{ ~x }> => (occuring_vars x)
  | <{ x -> y }> => set_union (occuring_vars x) (occuring_vars y)
  end.

Example test_occuring_vars :occuring_vars twotwoone = [Id 1; Id 0]. 
Proof. reflexivity. Qed.

(* Computes a list of all possible valuations, given a list id possible id's *)
Fixpoint allValuations (l : list id) : list valuation :=
  match l with
  | nil => [empty_valuation]
  | x :: l' => let lv := allValuations l' in (map (fun V => override V x false) lv) ++ (map (fun V => override V x true) lv) 
  end.

(* Expecting length 4, since 2 variables both with mappings to true/false *)
Example test_length_of_allValuations : length (allValuations (occuring_vars twotwoone)) = 4.
Proof. reflexivity. Qed.

Fixpoint find_valuation_helper (p : form) (l : list valuation) : option valuation :=
  match l with
  | nil => None
  | v :: l' => if interp v p then Some v else find_valuation_helper p l'
  end.

Definition find_valuation (p : form ) : option valuation :=
  find_valuation_helper p (allValuations (occuring_vars p)).

Definition solver (p : form ) : bool :=
  match find_valuation p with
  | Some _ => true
  | None => false
  end.

(* Exercse 2.6

   Satisfiable is a definition, stating that there exists some valuation in which the formula is true.
   It requires you to provide a witness, namely a valuation in which the formula's interpretation is true.

   Solver is a function which returns true / false, depending on whether or not the formula is satisfiable,
   enumerating all possible valuations to find one.
*)

(* Exercise 2.7 *)

Example two7pos1 : solver twotwoone = true.
Proof. reflexivity. Qed.

Example two7pos2 : solver twotwotwo = true.
Proof. reflexivity. Qed.

Example two7neg1 : solver twotwothree = false.
Proof. reflexivity. Qed.

Example two7neg2 : solver <{ (x \/ y) /\ (~x \/ y) /\ (x \/ ~y) /\ (~x \/ ~y)  }> = false.
Proof. reflexivity. Qed.

Lemma solver_sound_helper : forall l p v, find_valuation_helper p l = Some v -> interp v p = true.
Proof. intros l. induction l; intros.
  - easy.
  - cbn in H. destruct (interp a p) eqn:E. inversion H. subst. auto. apply (IHl _ _ H).
Qed.

(* Exercise 2.8
   The proof that the solver is sound. Uses a helper function defined above to do so.
*)
Lemma solver_sound : forall p, solver p = true -> satisfiable p.
Proof. intros. unfold satisfiable. unfold solver in H. destruct (find_valuation p) eqn:E; try easy. exists v.
  unfold find_valuation in E. apply solver_sound_helper in E. auto.
Qed.

(* Helper lemma stating that an equivalent valuation exists in the list of allValuations, 
   for all possible valuations over the id's in said valuation 
*)
Lemma val_in_allvals : forall l (v: valuation), exists v', In v' (allValuations l) /\ forall x0, In x0 l ->  v x0 = v' x0.
Proof. induction l; intros.
  - exists Ø. split. left. reflexivity. intros. inversion H.
  - destruct (IHl v) as [v']. destruct H. destruct (v a) eqn:E1. 
    + exists (v'|[a |-> true]|). cbn. remember (fun V : valuation => V |[ a |-> true ]|) as f. assert (f v' = (v'|[a |-> true]|)) by (rewrite Heqf; reflexivity).
       split.
        * apply in_app_iff. right. rewrite <- H1. apply in_map. auto.
        * intros. destruct H2.
          -- subst. unfold override. rewrite <- beq_id_refl. apply E1.
          -- apply H0 in H2. destruct (beq_id a x0) eqn:E; 
            unfold override; rewrite E.
            ++ symmetry in E. apply beq_id_eq in E. subst. assumption.
            ++ unfold override. apply H2.
    + exists (v'|[a |-> false]|). cbn. remember (fun V : valuation => V |[ a |-> false ]|) as f. assert (f v' = (v'|[a |-> false]|)) by (rewrite Heqf; reflexivity).
    split.
      * apply in_app_iff. left. rewrite <- H1. apply in_map.  auto.
      * intros. destruct H2.
        -- subst. unfold override. rewrite <- beq_id_refl. apply E1.
        -- apply H0 in H2. destruct (beq_id a x0) eqn:E; unfold override; rewrite E. 
          ++ symmetry in E. apply beq_id_eq in E. subst. assumption.
          ++ apply H2.
Qed.

(* Following couple of functions are helper functions for performing set operations on lists. *)
Lemma in_set_add: forall x l, In x (set_add x l).
Proof. intros. induction l. 
  - cbn. left. reflexivity.
  - cbn. destruct (beq_id a x0) eqn:E.
    + symmetry in E. apply beq_id_eq in E. subst. left. reflexivity.
    + cbn. right. auto.
Qed.

Lemma in_set_add': forall x a l, In x l -> In x (set_add a l).
Proof. intros. induction l.
      * inversion H.
      * cbn. destruct (beq_id a0 a) eqn:E. auto. destruct H.
        ++ subst. left. reflexivity.
        ++ right. auto.
Qed.

Lemma in_set_union_l: forall x l1 l2, In x l1 -> In x (set_union l1 l2).
Proof. intros. induction l1.
  - inversion H.
  - destruct H.
    + subst. cbn. apply in_set_add.
    + cbn. apply in_set_add'. auto. 
Qed.

Lemma in_set_union_r: forall x l1 l2, In x l2 -> In x (set_union l1 l2).
Proof. intros. induction l1.
  - cbn. auto.
  - cbn. apply in_set_add'. auto. 
Qed.
    
(* If a formula is satisfiable then a valuation exists over the occuring vars which interpretation is true *)
Lemma satisfiable_helper : forall p, satisfiable p -> exists v, In v (allValuations (occuring_vars p)) /\ interp v p = true.
Proof. intros. destruct H as [v]. destruct (val_in_allvals (occuring_vars p) v) as [v']. destruct H0. exists v'.
  split.
    - apply H0.
    - clear H0. rewrite <- H. clear H. induction p; cbn;
      try reflexivity; try (rewrite <- H1; auto; left; auto);
      try (rewrite IHp1, IHp2; try reflexivity; intros; apply H1; cbn; [ apply in_set_union_r |  apply in_set_union_l]; auto);
      (rewrite IHp; auto).
Qed.

Lemma solver_complete_help : forall l p v, interp v p = true -> In v l -> exists v', find_valuation_helper p l = Some v'.
Proof. induction l; intros.
  - easy.
  - destruct H0.
    + subst. exists v. cbn. rewrite H. reflexivity.
    + cbn. destruct (interp a p); eauto.
Qed.

(* Exercise 2.9. Proof of completeness of the solver. *)
Lemma solver_complete : forall p, satisfiable p -> solver p = true.
Proof. 
  intros. unfold solver, find_valuation. apply satisfiable_helper in H. destruct H. destruct H.
  pose proof (solver_complete_help (allValuations (occuring_vars p)) p x0 H0 H). 
  destruct H1. rewrite H1. reflexivity.
Qed. 

(* Transforms (p1 -> p2) into (~p1 \/ p2) *)
Fixpoint negation_nf_1 p :=
  match p with
  | <{ p1 -> p2 }> => f_or (f_neg (negation_nf_1 p1)) (negation_nf_1 p2) 
  | <{ p1 /\ p2 }> => f_and (negation_nf_1 p1) (negation_nf_1 p2) 
  | <{ p1 \/ p2 }> => f_or (negation_nf_1 p1) (negation_nf_1 p2) 
  | <{ ~p1 }> => f_neg (negation_nf_1 p1)
  | _ => p
  end.

(* De Morgan's Law, transforming ~(p1 \/ p2) into (~p1) /\ (~p2) and ~(p1 /\ p2) into (~p1) \/ (~p2)
   Note. This is only called on negations, so whenever (p1 \/ p2) is encountered, this is actually
   ~(p1 \/ p2). Therefore, if ~p1 is seen this actually means ~~p1 which is why p1 is returned (double neg elim).
*)
Fixpoint de_morg p :=
  match p with
  | <{(p1 \/ p2) }> => f_and (de_morg p1) (de_morg p2)  
  | <{(p1 /\ p2) }> => f_or (de_morg p1) (de_morg p2) 
  | f_neg p1 => p1
  | _ => f_neg p
  end.

(* Applies De Morgan's Law + double negation elimination to a formula which is assumed to have no implications *)
Fixpoint negation_nf_2 p :=
  match p with
  | <{ ~p1 }> => de_morg (negation_nf_2 p1)
  | <{ p1 /\ p2 }> => f_and (negation_nf_2 p1) (negation_nf_2 p2) 
  | <{ p1 \/ p2 }> => f_or (negation_nf_2 p1) (negation_nf_2 p2) 
  | _ => p
  end.

(* Converts an arbitrary formula into an equivalent one on NNF *)
Definition negation_nf p := 
  let p1 := negation_nf_1 p in
  negation_nf_2 p1.

Fixpoint distr_left p q :=
  match q with
  | <{q1 /\ q2 }> => f_and (distr_left p q1) (distr_left p q2)
  | _ => <{p \/ q}>
  end.

Fixpoint distr_right q p :=
  match q with
  | <{q1 /\ q2 }> => f_and (distr_right q1 p) (distr_right q2 p)
  | _ => distr_left q p
  end.

(* Distributes Disjunctions from left and right *)
Definition distribute p := 
  match p with
  | <{p \/ q}> => distr_right p q
  | _ => p
  end.

(* Assuming s is on negation normal form, turns it into cnf *)
Fixpoint cnf s :=
  match s with
  | <{ p /\ q }> => f_and (cnf p) (cnf q)
  | <{ p \/ q}> => distribute (f_or (cnf p) (cnf q))
  | _ => s
  end.

(* Converts a boolean formula to CNF *)
Definition cnf_conv p := 
  let p1 := negation_nf p in
  cnf p1.

Fixpoint verify_cnf_aux s (seenor : bool) :=
  match s with
  | <{ p /\ q }> => if seenor then false else (verify_cnf_aux p false) && (verify_cnf_aux q false)
  | <{ p \/ q }> => (verify_cnf_aux p true) && (verify_cnf_aux q true)
  | f_false | f_true | f_var _ => true
  | f_neg (f_var _) | f_neg (f_false) | f_neg (f_true)  => true
  | _ => false
  end.

(* Verifies that a formula is on CNF - uses helper function to ensure no more conjunctions are seen after the first disjunction*)
Definition verify_cnf s := verify_cnf_aux s false.

Conjecture cnf_works : forall p, verify_cnf (cnf_conv p) = true.

(* Check that the semantics of cnf_conv is preserved *)
Conjecture cnf_sat : forall p, solver p = solver (cnf_conv p).

From QuickChick Require Import QuickChick.

(* Derivies arbitrary for required parts, and executes QuickChick on the defined Conjectures. *)
Derive Arbitrary for id.
Derive Arbitrary for form.
Derive Show for id.
Derive Show for form.


QuickChick cnf_works.
QuickChick cnf_sat.