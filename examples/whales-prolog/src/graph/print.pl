% ----------------------------------------------------------------
% EXPORTS
% ----------------------------------------------------------------

:- module(print, [printPath/2, printPaths/2]).

% ----------------------------------------------------------------
% IMPORTS
% ----------------------------------------------------------------

% :- use_module(core/utils, [printList/1]).
:- use_module(data/data, [start/1]).
:- use_module(data/data, [end/1]).
% :- use_module(data/data, [edge/2]).

% ----------------------------------------------------------------
% printPath/2, printPaths/2, printPathRec/2
% ----------------------------------------------------------------

printPaths(_, [])           :- write('--- no paths found! ---').
printPaths(Name, [P])       :- printPath(Name, P).
printPaths(Name, [P|Paths]) :- printPath(Name, P), write('\n'), printPaths(Name, Paths).
printPath(Name, P)          :- write(Name), write(': '), printPathRec(P), write('.').

printPathRec([]) :- write('').
printPathRec([X]) :- start(X), write('('), write(X), write(')').
printPathRec([X]) :- end(X), write('(('), write(X), write('))').
printPathRec([X]) :- write(X).
printPathRec([X|P]) :- printPathRec([X]), write(' ~~> '), printPathRec(P).
