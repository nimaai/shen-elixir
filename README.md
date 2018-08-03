* Elixir port of Shen

This is an interpreted port of [Shen](shenlanguage.org). It is very slow.

Times were measured on a MacBook Pro (2016, 2.9GHz Intel Core 17, 16 GB RAM).

* Klambda REPL

`mix run lib/repl.exs`

* Bootstrap Shen

`mix run lib/bootstrap.exs`

It takes about 85 seconds.

* Bootstrap Shen

`mix run lib/bootstrap.exs`

It takes about 85 seconds.

* Running tests

```
mix run lib/bootstrap.exs
(cd "shen-sources/tests")
(load "README.shen")
(load "tests.shen")
```

There used to be only failing test, but now it is broken due some other reason.
