defmodule KL.Types do
  @type expr :: kl_atom | function_application
  @type kl_atom :: atom
                 | String.t
                 | number
                 | boolean
                 | pid
                 | function
                 | %KL.SimpleError{}
  @type env :: map
  @type function_application :: [operator | list(expr)]
  @type operator :: atom | function_application
end
