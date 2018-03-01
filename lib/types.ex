defmodule KL.Types do
  @type expr :: kl_term | function_application
  @type kl_term :: atom
                 | String.t
                 | number
                 | boolean
                 | pid
                 | function
                 | maybe_improper_list
                 | %KL.SimpleError{}
                 | nil
  @type env :: map
  @type function_application :: [operator | list(expr)]
  @type operator :: atom | function_application
end
