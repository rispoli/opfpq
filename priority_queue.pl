% Gerth Stølting Brodal and Chris Okasaki - Optimal purely functional priority queues
% Paper: http://www.cs.au.dk/~gerth/pub/jfp96.html
% Technical report: http://www.cs.au.dk/~gerth/pub/brics-rs-96-37.html
% SML source code: http://www.eecs.usma.edu/webs/people/okasaki/jfp96/index.html

:- module(priority_queue, [is_empty/1, insert/3, meld/3, find_min/2, find_min_b/2, delete_min/2, from_list/2, to_list/2]).

is_empty([]).

skew_link(node(X0, R0, CF0), node(X1, R1, CF1), node(X2, R2, CF2), node(X1, R1_, [node(X0, R0, CF0), node(X2, R2, CF2) | CF1])) :-
    leq(X1, X0),
    leq(X1, X2), !,
    R1_ is R1 + 1.

skew_link(node(X0, R0, CF0), node(X1, R1, CF1), node(X2, R2, CF2), node(X2, R2_, [node(X0, R0, CF0), node(X1, R1, CF1) | CF2])) :-
    leq(X2, X0),
    leq(X2, X1), !,
    R2_ is R2 + 1.

skew_link(node(X0, _, CF0), node(X1, R1, CF1), node(X2, R2, CF2), node(X0, R1_, [node(X1, R1, CF1), node(X2, R2, CF2) | CF0])) :-
    R1_ is R1 + 1.

skew_insert(T, [node(X1, R, F1), node(X2, R, F2) | Rest], [O | Rest]) :-
    !, skew_link(T, node(X1, R, F1), node(X2, R, F2), O).

skew_insert(T, TS, [T | TS]).

insert(X, [], node(X, 0, [])) :- !.

insert(X, node(Y, R, F), node(X, 0, [node(Y, R, F)])) :-
    leq(X, Y), !.

insert(X, node(Y, _, F), node(Y, 0, O)) :-
    skew_insert(node(X, 0, []), F, O).

meld([], Q, Q) :- !.

meld(Q, [], Q) :- !.

meld(node(X1, _, F1), node(X2, R2, F2), node(X1, 0, O)) :-
    leq(X1, X2), !,
    skew_insert(node(X2, R2, F2), F1, O).

meld(node(X1, R1, F1), node(X2, _, F2), node(X2, 0, O)) :-
    skew_insert(node(X1, R1, F1), F2, O).

find_min([], _) :-
    throw(empty_priority_queue).

find_min(node(X, _, _), X).

find_min_b([], _) :- !, fail.

find_min_b(node(X, _, _), X).

find_min_b(Q, X) :-
    delete_min(Q, Q_),
    find_min_b(Q_, X).

get_min([T], (T, [])) :- !.

get_min([node(XT, RT, FT) | TS], O) :-
    get_min(TS, (node(XT_, RT_, FT_), TS_)),
    ((leq(XT, XT_)) ->
        O = (node(XT, RT, FT), TS);
        O = (node(XT_, RT_, FT_), [node(XT, RT, FT) | TS_])).

split(0, ZS, TS, F, (ZS, TS, F)) :- !.

split(1, ZS, TS, [T], (ZS, [T | TS], [])) :- !.

split(1, ZS, TS, [T1, node(X2, 0, F2) | F], ([T1 | ZS], [node(X2, 0, F2) | TS], F)) :- !.

split(1, ZS, TS, [T1, T2 | F], (ZS, [T1 | TS], [T2 | F])) :- !.

split(_, ZS, TS, [node(X1, R_, F1), node(X2, R_, F2) | CF], (ZS, [node(X1, R_, F1), node(X2, R_, F2) | TS], CF)) :- !.

split(R, ZS, TS, [node(X1, 0, F1), T2 | CF], O) :-
    !, R_ is R - 1,
    split(R_, [node(X1, 0, F1) | ZS], [T2 | TS], CF, O).

split(R, ZS, TS, [T1, T2 | CF], O) :-
    R_ is R - 1,
    split(R_, ZS, [T1 | TS], [T2 | CF], O).

link(node(X1, R1, CF1), node(X2, R2, CF2), node(X1, R1_, [node(X2, R2, CF2) | CF1])) :-
    leq(X1, X2), !,
    R1_ is R1 + 1.

link(node(X1, R1, CF1), node(X2, R2, CF2), node(X2, R2_, [node(X1, R1, CF1) | CF2])) :-
    R2_ is R2 + 1.

ins(T, [], [T]) :- !.

ins(node(XT, RT, FT), [node(XT_, RT_, FT_) | TS], [node(XT, RT, FT), node(XT_, RT_, FT_) | TS]) :-
    RT < RT_, !.

ins(T, [T_ | TS], O) :-
    link(T, T_, L_O),
    ins(L_O, TS, O).

uniqify([], []).

uniqify([T | TS], O) :-
    ins(T, TS, O).

meld_uniq([], TS, TS) :- !.

meld_uniq(TS, [], TS) :- !.

meld_uniq([node(X1, R1, F1) | TS1], [node(X2, R2, F2) | TS2], [node(X1, R1, F1) | O]) :-
    R1 < R2, !,
    meld_uniq(TS1, [node(X2, R2, F2) | TS2], O).

meld_uniq([node(X1, R1, F1) | TS1], [node(X2, R2, F2) | TS2], [node(X2, R2, F2) | O]) :-
    R2 < R1, !,
    meld_uniq([node(X1, R1, F1) | TS1], TS2, O).

meld_uniq([T1 | TS1], [T2 | TS2], O) :-
    link(T1, T2, L_O),
    meld_uniq(TS1, TS2, MU_O),
    ins(L_O, MU_O, O).

skew_meld(TS, TS_, O) :-
    uniqify(TS, U_TS),
    uniqify(TS_, U_TS_),
    meld_uniq(U_TS, U_TS_, O).

foldr(_, Z, [], Z) :- !.

foldr(F, Z, [X | XS], O) :-
    foldr(F, Z, XS, F_O),
    C =.. [F, X, F_O, O],
    C.

delete_min([], _) :-
    throw(empty_priority_queue).

delete_min(node(_, _, []), []) :- !.

delete_min(node(_, _, F), node(X_, 0, O)) :-
    get_min(F, (node(X_, R, CF), TS2)),
    split(R, [], [], CF, (ZS, TS1, FS)),
    skew_meld(TS1, TS2, SKM_O1),
    skew_meld(SKM_O1, FS, F_),
    foldr(skew_insert, F_, ZS, O).

foldl(_, Z, [], Z) :- !.

foldl(F, Z, [X | XS], O) :-
    C =.. [F, X, Z, C_O],
    C,
    foldl(F, C_O, XS, O).

from_list(L, Q) :-
    foldl(insert, [], L, Q).

to_list(Q, L, LR) :-
    catch((find_min(Q, X), delete_min(Q, Q_)), empty_priority_queue, reverse(L, LR)),
    (var(X) ->
        true;
        to_list(Q_, [X | L], LR)).

to_list(Q, L) :-
    to_list(Q, [], L).
