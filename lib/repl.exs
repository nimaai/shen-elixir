alias Lisp.Bindings
alias Lisp.Reader
alias Lisp.Primitives

{:ok, functions_pid} = Bindings.start_link(Primitives.mapping)

Reader.read_input %{functions: functions_pid}
