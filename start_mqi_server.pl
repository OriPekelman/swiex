#!/usr/bin/env swipl

:- use_module(library(mqi)).

% Start MQI server on port 12347 with password "test"
:- mqi_start([port(12347), password("test")]).

% Keep the server running
:- thread_get_message(_). 