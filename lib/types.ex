defmodule Klambda.Types do
  @type expr :: kl_atom | function_application
  @type kl_atom :: atom
                 | String.t
                 | number
                 | boolean
                 | pid
                 | function
                 | simple_error
  @type env :: map
  @type simple_error :: {:"simple-error", String.t}
  @type function_application :: [operator | list(expr)]
  @type operator :: atom | function_application
end
