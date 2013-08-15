defmodule GenserverDsl do

  @moduledoc """
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

  `register`
    The specification of the name under which to register the server. For
    example, if you wanted to register globally as `:fred`, do

        use GenserverDsl, register: { :global, :fred }

    The option defaults to `{ :local, my_name }`, where `my_name` is
    an atom derived from the module name.

  `initial_state` 
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
  """


  @doc nil
  defmacro __using__(options) do
    register      = Keyword.get(options, :register,      nil)
    initial_state = Keyword.get(options, :initial_state, nil)
#    tracing       = Keyword.get(options, :trace,         false)

    quote do
      use GenServer.Behaviour
      import unquote(__MODULE__)

      if unquote(register) do
        def my_name do
          elem(unquote(register), 1)
        end

        def start_link() do
          :gen_server.start_link(unquote(register), __MODULE__, unquote(initial_state), [])
        end
      else
        def my_name do
          name_from(__MODULE__)
        end
        def start_link() do
          :gen_server.start_link({:local, my_name}, __MODULE__, unquote(initial_state), [])
        end
      end

    end
  end

  @doc """
  Define both a module API and the function that handles calls to that API in the server.
  For example, if you write

      defcall increment(n) do
        reply(n+1)
      end

  You will get the following two functions defined

     def increment(n) do
       gen_server.call(my_name, {:increment, n})
     end

     def handle_call({:increment, n}, _from, state) do
       { :reply, n+1, state }
     end
  """

  defmacro defcall({name, _, params}=defn, do: body) do
    quote do
      def unquote(defn) do
        :gen_server.call(my_name, {unquote(name), unquote_splicing(params)})
      end

      def handle_call({unquote(name), unquote_splicing(params)}, var!(_from, nil), var!(state, nil)) do 
        unquote(body)
      end
    end
  end

  @doc """
  Generate a reply from a call handler that does not change the state.  The value will be
  returned as the second element of the :reply tuple.
  """
  defmacro reply(value) do
    quote do
      { :reply, unquote(value), var!(state) }
    end
  end

  @doc """
  Generate a reply from a call handler and also set the state.  The value will be
  returned as the second element of the :reply tuple, and the new state as the third.
  """
  defmacro reply_with_state(args, new_state) do
    quote do
      { :reply, unquote(args), unquote(new_state) }
    end
  end

  #####
  # Ideally should be private, but...

  def name_from(module_name) do
    Regex.replace(%r{(.)\.?([A-Z])}, inspect(module_name), "\\1_\\2") 
    |> String.downcase
    |> binary_to_atom
  end
end