defexception ExRecord.MissingVersionField, record: nil, field: nil do
  def message(e) do
    "Record #{inspect e.record} is missing version field #{e.field}"
  end
end

defexception ExRecord.InvalidVersionFieldPosition, record: nil, field: nil,
                                                   expected: 0, actual: nil do
  def message(e) do
    "Record #{inspect e.record} has version field #{e.field} at a position #{e.actual} instead of #{e.expected}"
  end
end

defmodule ExRecord do
  defmacro __using__(opts) do
    version_field = opts[:version] || :__version__
    convert = opts[:convert] || :__convert__
    quote do
      unless (Module.defines?(__MODULE__, {unquote(version_field), 1}) and
              Module.defines?(__MODULE__, {unquote(version_field), 2})) do
        raise ExRecord.MissingVersionField, record: __MODULE__, 
                                            field: unquote(version_field)                                                   
      end
      unless hd(Keyword.keys(@__record__)) == unquote(version_field) do
        raise ExRecord.InvalidVersionFieldPosition, record: __MODULE__, 
                                                    field: unquote(version_field),
                                                    expected: 0, 
                                                    actual: Enum.find_index(Keyword.keys(@__record__),
                                                                            fn(x) -> x == unquote(version_field) end)
      end

      defoverridable new: 1
      def new(opts) do
        rec = super(opts)
        apply(rec, unquote(version_field), [{apply(rec, unquote(version_field), []),
                                             Keyword.keys(__record__(:fields))}])
      end

      def unquote(convert)(src) do 
        {version, fields} = elem(src, 1)
        [__MODULE__|src] = tuple_to_list(src)
        [_version|src] = Enum.zip(fields, src)
        unless version == 
               __record__(:fields)[unquote(version_field)] do
          unquote(convert)(version, src)
        else
          src
        end
      end
      def unquote(convert)(_version, src) do
        new(Keyword.delete(src, unquote(version_field)))      
      end
      defoverridable [{unquote(convert), 2}]
    end
  end
end