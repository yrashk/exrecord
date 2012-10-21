# ExRecord

ExRecord is a simple convention and a library to facilitate easier Elixir record
upgrades (normally during code change / release upgrades).

## Definition

In order to benefit from ExRecord, define your records this way:

```elixir
defrecord MyRecord, __version__: 1, field: nil do
  use ExRecord
end
```

You can also rename `__version__` to any other name:

```elixir
use ExRecord, version: :__version_field__
```

## Use

In order to upgrade (or downgrade) your record, call `MyRecord.__convert__(record_to_be_converted)` and you'll get a converted up-to-date record.

By default, the algorithm for conversion is very simple: it takes the original
(to be converted record), extracts all fields values and creates a new record with these
fields. It will silently ignore fields that no longer exist in the actual record.

You can also override a convertion procedure for any version by overriding `__convert__(version, record)` function:

```elixir
defrecord TestCustomChangeRecord, __version__: 2, a: 1 do
  use ExRecord

  def __convert__(1, src) do
    super(version, src).a(2)
  end
end
```

You can also rename the `__convert__` function:

```elixir
use ExRecord, convert: :__my_convert__
```

## Example

```elixir
iex(1)> defrecord Foo, __version__: 1, bar: nil do
...(1)>   use ExRecord
...(1)> end
{:module,Foo,<<70,79,82,49,0,0,9,200,66,69,65,77,65,116,111,109,0,0,1,121,0,0,0,39,10,69,108,105,120,105,114,45,70,111,111,8,95,95,105,110,102,111,95,95,4,100,111,99,115,9,...>>,[true]}
iex(2)> Foo.new(bar: 1)
Foo[__version__: {1,[:__version__,:bar]}, bar: 1]
iex(3)> inspect v(-1), raw: true
"{Foo,{1,[:__version__,:bar]},1}"
```

Now, let's remember this binary and reuse it in a new IEx session:

```elixir
iex(1)> defrecord Foo, __version__: 2, bar: nil, foo: nil do
...(1)>   use ExRecord
...(1)> end
{:module,Foo,<<70,79,82,49,0,0,10,192,66,69,65,77,65,116,111,109,0,0,1,136,0,0,0,41,10,69,108,105,120,105,114,45,70,111,111,8,95,95,105,110,102,111,95,95,4,100,111,99,115,9,...>>,[true]}
iex(2)> record = {Foo,{1,[:__version__,:bar]},1}
{Foo,{1,[:__version__,:bar]},1}
iex(3)> Foo.__convert__(record)
Foo[__version__: {2,[:__version__,:bar,:foo]}, bar: 1, foo: nil]
```

As you can see, the old record got automatically converted to a new record that contains
more fields.

## Notes

It is important to understand that each ExRecordified record will carry its version & field information in the very first field:

```elixir
iex(1)> defrecord Foo, __version__: 1, bar: 2 do
...(1)>   use ExRecord
...(1)> end
{:module,Foo,<<70,79,82,49,0,0,10,56,66,69,65,77,65,116,111,109,0,0,1,135,0,0,0,40,10,69,108,105,120,105,114,45,70,111,111,8,95,95,105,110,102,111,95,95,4,100,111,99,115,9,...>>,[true]}
iex(2)> Foo.new
Foo[__version__: {1,[:__version__,:bar]}, bar: 2]
```

Also, you don't need to have a runtime dependency on the `exrecord` application as all work is done during compile time. All of the conversion code gets compiled into your record modules.