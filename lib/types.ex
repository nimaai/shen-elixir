defmodule Kl.Types do
  @type expr :: kl_term | function_application
  @type kl_term :: atom
                 | String.t
                 | number
                 | boolean
                 | {:vector, pid}
                 | {:stream, pid}
                 | function
                 | maybe_improper_list
                 | %Kl.SimpleError{}
                 | nil
  @type env :: map
  @type function_application :: [operator | list(expr)]
  @type operator :: atom | function_application
end
