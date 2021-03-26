% ----------------------------------------------------------------
% EXPORTS
% ----------------------------------------------------------------

:- module(paths, [path/4, getPath/3, getPaths/3]).

% ----------------------------------------------------------------
% IMPORTS
% ----------------------------------------------------------------

:- use_module(data/data,     [edge/2]).
:- use_module(graph/basic,   [bounded/2]).

% ----------------------------------------------------------------
% path/4, path/5
% ----------------------------------------------------------------

% NOTE: V = list of 'nodes so far'.
path(X,X,[],P) :- path(X,X,[],P,_).          % if start == end, then do not add start node to V.
path(X,Y,[],P) :- Y \= X, path(X,Y,[X],P,_). % if start != end, then add start node to V.
% NOTE: path/5 ensures recursive computation initialises (in path/4) exactly once
path(X,X,V,[X],1)     :- bounded(X,V).
path(X,Z,V,[X|P],N+1) :- append(V,[Y],VV), edge(X,Y), bounded(X,VV), bounded(Y,VV), path(Y,Z,VV,P,N).

% ----------------------------------------------------------------
% getPath/3, getPaths/3
% ----------------------------------------------------------------

getPath(X,Y,P)      :- path(X,Y,[],P).
getPaths(X,Y,Paths) :- bagof(P, path(X,Y,[],P), Paths_), sort(Paths_, Paths).
