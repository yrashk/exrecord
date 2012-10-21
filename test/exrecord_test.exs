Code.require_file "../test_helper.exs", __FILE__

defrecord TestRecord, __version__: 1 do
  use ExRecord
end

defrecord TestCustomRecord, __my_version__: 1 do
  use ExRecord, version: :__my_version__
end

defrecord TestCustomChangeRecord, __version__: 1, a: 1 do
  use ExRecord

  def __convert__(version, src) do
    super(version, src).a(2)
  end
end

defrecord TestCustomChangeRecord1, __version__: 1, a: 1 do
  use ExRecord, convert: :__my_convert__

  def __my_convert__(version, src) do
    super(version, src).a(2)
  end
end


defmodule ExRecordTest do
  use ExUnit.Case

  test "record without version field" do
    assert ExRecord.MissingVersionField[field: :__version__, 
                                        record: ExRecordTest.MyRecord] =
    catch_error(
      defrecord MyRecord, a: 1 do
        use ExRecord
      end)
    :code.delete MyRecord
    :code.purge MyRecord
  end

  test "record without custom version field" do
    assert ExRecord.MissingVersionField[field: :__my_version__, 
                                        record: ExRecordTest.MyRecord] =
    catch_error(
      defrecord MyRecord, a: 1 do
        use ExRecord, version: :__my_version__
      end)
    :code.delete MyRecord
    :code.purge MyRecord
  end

  test "record with misplaced version field" do
    assert ExRecord.InvalidVersionFieldPosition[field: :__version__, 
                                                record: ExRecordTest.MyRecord,
                                                expected: 0, actual: 1] =
    catch_error(
      defrecord MyRecord, a: 1, __version__: 1 do
        use ExRecord
      end)
    :code.delete MyRecord
    :code.purge MyRecord
  end

  test "record with misplaced custom version field" do
    assert ExRecord.InvalidVersionFieldPosition[field: :__my_version__, 
                                                record: ExRecordTest.MyRecord,
                                                expected: 0, actual: 1] =
    catch_error(
      defrecord MyRecord, a: 1, __my_version__: 1 do
        use ExRecord, version: :__my_version__
      end)
    :code.delete MyRecord
    :code.purge MyRecord
  end

  test "record with default change implementation" do
    assert TestRecord.__convert__(TestRecord.new(__version__: 2)) == TestRecord.new
  end

  test "record with a custom version field with default change implementation" do
    assert TestCustomRecord.__convert__(TestCustomRecord.new(__my_version__: 2)) == TestCustomRecord.new
  end

  test "record with custom change implementation" do
    assert TestCustomChangeRecord.__convert__(TestCustomChangeRecord.new(__version__: 2)) == TestCustomChangeRecord.new(a: 2)
  end

  test "record with customly named change implementation" do
    assert TestCustomChangeRecord1.__my_convert__(TestCustomChangeRecord1.new(__version__: 2)) == TestCustomChangeRecord1.new(a: 2)
  end

  test "convert algorithm doesn't use old record module" do
    quoted = quote do
      defrecord Record1, __version__: 1, a: 1 do
        use ExRecord
      end
    end
    Code.eval_quoted quoted
    rec = Record1.new
    :code.delete Record1
    :code.purge Record1
    quoted = quote do    
      defrecord Record1, __version__: 2, b: 1 do
        use ExRecord
      end
    end
    Code.eval_quoted quoted    
    assert Record1.__convert__(rec) == Record1.new
    :code.delete Record1
    :code.purge Record1    
  end

end
