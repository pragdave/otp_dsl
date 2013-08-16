# ServerDsl

A simple DSL wrapper for GenServer modules. It reduces duplication by
exploiting the fact that a GenServer module typically has an API function
that calls a corresponding handle_call function that runs on the server
process. We wrap those two functions into one macro. For example, the following
module is a GenServer with a single API, `factorial`.

    defmodule FactorialServer do
      use GenserverDsl

      defcall factorial!(n) do
        reply(Enum.reduce(1..n, 1, &(&1*&2)))
      end
    end

You could start this from a supervisor, or manually with
`FactorialServer.start_link`. You can then call the function 
in the server process using 

    FactorialServer.factorial!(10)

The `use` function takes the following options:

* `register`

  The specification of the name under which to register the server. For
   example, if you wanted to register globally as `:fred`, do

      use GenserverDsl, register: { :global, :fred }

  The option defaults to `{ :local, my_name }`, where `my_name` is
  an atom derived from the module name.

* `initial_state` 

  A value representing an initial state for tbe server. Defaults to
  `nil`.

## Example

Here's a server that implements a simple key/value store:


    defmodule KvServer do
      use GenserverDsl, initial_state: HashDict.new

      defcall put(key, value) do
        reply_with_state(value, Dict.put(state, key, value))
      end

      defcall get(key) do
        reply(Dict.get(state, key))
      end
    end

Note the use of `reply_with_state`. This is used to return a value and
also to update the server state.


## Copyright

Copyright © 2013 Dave Thomas, The Pragmatic Programmers

Licensed for use under the same terms as Elixir
