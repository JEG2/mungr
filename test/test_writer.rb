# encoding: UTF-8

require "helper"

require "mungr/writer"

class TestWriter < MiniTest::Unit::TestCase
  ##############
  ### Status ###
  ##############
  
  def test_a_writer_is_prepared_before_the_first_write
    order = Array.new
    writer do |w|
      w.prepare { order << :prepared }
      w.write   do
        order << :write
      end
    end
    assert(!@writer.prepared?, "The Writer was prepared?() before the write().")
    @writer.write("data")
    assert( @writer.prepared?,
            "The Writer was not prepared?() after the write()." )
    assert_equal([:prepared, :write], order)
  end
  
  ###############
  ### Context ###
  ###############
  
  def test_any_value_returned_from_prepare_is_forwarded_to_write_and_finish
    object = Object.new
    calls  = Array.new
    writer do |w|
      w.prepare { object }
      w.write   do |context|
        calls << context
      end
      w.finish  do |context|
        calls << context
      end
    end
    @writer.write("data")  # trigger write code
    @writer.finish         # trigger finish code
    assert_equal([object] * 2, calls)
  end
  
  ###############
  ### Writing ###
  ###############
  
  def test_calling_write_a_with_block_sets_the_code_and_further_calls_run_it
    data     = (1..3).to_a
    written  = Array.new
    writer do |w|
      w.write do |_, value|
        written << value
      end
    end
    data.each do |value|
      @writer.write(value)
    end
    assert_equal(data, written)
  end
  
  def test_prepare_is_called_once_before_the_first_read
    data  = (1..3).to_a
    calls = Array.new
    writer do |w|
      w.prepare { calls << :prepare }
      w.write   do |_, value|
        calls << value
      end
    end
    data.each do |value|
      @writer.write(value)
    end
    assert_equal([:prepare] + data, calls)
  end
end
