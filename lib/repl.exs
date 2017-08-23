alias Lisp.Bindings
alias Lisp.Reader
alias Lisp.Primitives

{:ok, functions_pid} = Bindings.start_link(Primitives.mapping)
{:ok, globals_pid}= Bindings.start_link(%{})

Reader.read_input %{
  locals: %{},
  globals: globals_pid,
  functions: functions_pid
}
