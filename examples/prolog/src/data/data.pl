% ----------------------------------------------------------------
% EXPORTS
% ----------------------------------------------------------------

:- module(data, [edge/2,start/1,end/1,constraint/2]).

% ----------------------------------------------------------------
% IMPORTS
% ----------------------------------------------------------------

%

% ----------------------------------------------------------------
% start/1, end/1
% ----------------------------------------------------------------

start(b1).
end(b5).
end(b7).

% ----------------------------------------------------------------
% edge/2
% ----------------------------------------------------------------

edge(b1,b2).
edge(b1,b3).
edge(b2,b4).
edge(b4,b5).
edge(b3,b6).
edge(b6,b2).
edge(b6,b7).
edge(b5,b7).
edge(b5,b8).
edge(b8,b2).

% ----------------------------------------------------------------
% constraint/2
% ----------------------------------------------------------------

constraint(b6, 3).
constraint(b8, 2).
