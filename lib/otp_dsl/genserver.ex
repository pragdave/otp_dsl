defmodule OtpDsl.Genserver do

  @moduledoc OtpDsl.Util.LazyDoc.for("## OtpDsl.Genserver")

  @hidden_state_name :s_t_a_t_e

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

     def handle_call({:increment, n}, _from, «state») do
       { :reply, n+1, «state» }
     end

  In this case, our server maintains no state of its own, so we fake out a
  state (shown as «state» above).

  If you need state, then pass in the name of the state parameter as a second 
  argument to defcall, and pass a new state out as a second parameter 
  to the `reply` call.

      defmodule KvServer do
        use OtpDsl.Genserver, initial_state: HashDict.new

        defcall put(key, value), kv_store do
          reply(value, Dict.put(kv_store, key, value))
        end

        defcall get(key), kv_store do
          reply(Dict.get(kv_store, key), kv_store)
        end
      end

  In this example, we make the state available in the variable
  `kv_store`.
  """

  defmacro defcall({name, meta, params}=defn, state_name // {@hidden_state_name, [], nil}, do: body) do
 
    quote do
      def unquote(defn) do
        :gen_server.call(my_name, {unquote(name), unquote_splicing(params)})
      end

      def handle_call({unquote(name), unquote_splicing(params)}, var!(_from, nil), unquote(state_name)) do
        case unquote(body) do
          { :reply, value, unquote(@hidden_state_name) } -> { :reply, value, unquote(state_name) }
          { :reply, value, new_state }          -> { :reply, value, new_state }
        end
      end
    end
  end

  defmacro defcast({name, meta, params}=defn, state_name // {@hidden_state_name, [], nil}, do: body) do

    quote do
      def unquote(defn) do
        :gen_server.cast(my_name, {unquote(name), unquote_splicing(params)})
      end

      def handle_cast({unquote(name), unquote_splicing(params)}, unquote(state_name)) do
        unquote(body)
      end
    end
  end

  @doc """
  Generate a reply from a call handler. The value will be
  returned as the second element of the :reply tuple. The optional
  second paramter gives the new state value. If omitted, it
  defaults to the value of the state passed into `handle_call`.
  """
  def reply(value),            do: { :reply, value, @hidden_state_name }
  def reply(value, new_state), do: { :reply, value, new_state }

  def noreply,            do: { :noreply, @hidden_state_name }
  def noreply(new_state), do: { :noreply, new_state }

  #####
  # Ideally should be private, but...

  def name_from(module_name) do
    Regex.replace(%r{(.)\.?([A-Z])}, inspect(module_name), "\\1_\\2")
    |> String.downcase
    |> binary_to_atom
  end
end
