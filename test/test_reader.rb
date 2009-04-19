# encoding: UTF-8

require "minitest/autorun"

require "mungr/reader"

class TestReader < MiniTest::Unit::TestCase
  ##############
  ### Status ###
  ##############
  
  def test_a_reader_is_prepared_before_the_first_read
    order = Array.new
    reader do |r|
      r.prepare { order << :prepared }
      r.read    { order << :read     }
    end
    assert(!@reader.prepared?, "The Reader was prepared?() before the read().")
    @reader.read
    assert( @reader.prepared?,
            "The Reader was not prepared?() after the read()." )
    assert_equal([:prepared, :read], order)
  end
  
  def test_exhausting_a_reader_sets_finished
    order = Array.new
    reader do |r|
      r.read {
        order << :read
        nil  # signal that we are exhausted
      }
      r.finish { order << :finished }
    end
    assert( !@reader.finished?,
            "The Reader was finished?() before being exhausted." )
    @reader.read
    assert( @reader.finished?,
            "The Reader was finished?() after being exhausted." )
    assert_equal([:read, :finished], order)
  end
  
  ###############
  ### Context ###
  ###############
  
  def test_any_value_returned_from_prepare_is_forwarded_to_read_and_finish
    object = Object.new
    calls  = Array.new
    reader do |r|
      r.prepare { object }
      r.read    { |context|
        calls << context
        nil  # signal that we are exhausted
      }
      r.finish  { |context| calls << context }
    end.read  # trigger read and finish code
    assert_equal([object] * 2, calls)
  end
  
  ###############
  ### Reading ###
  ###############
  
  def test_calling_read_a_with_block_sets_the_code_and_further_calls_run_it
    data     = (1..3).to_a
    expected = data.dup
    reader do |r|
      r.read { data.shift }
    end
    4.times do |i|
      assert_equal(expected[i], @reader.read)
    end
  end
  
  def test_a_nil_signals_that_input_is_exhausted_and_no_more_reads_are_made
    reader do |r|
      r.prepare { [nil] + (1..3).to_a }
      r.read    { |data| data.shift   }
    end
    5.times do
      assert_nil(@reader.read)
    end
  end
  
  def test_prepare_is_called_once_before_the_first_read
    calls = Array.new
    reader do |r|
      r.prepare {
        calls << :prepare
        (1..3).to_a
      }
      r.read    { |data|
        calls << :read
        data.shift
      }
    end
    @reader.read until @reader.finished?
    assert_equal([:prepare, :read, :read, :read, :read], calls)
  end
  
  def test_finish_is_called_once_when_the_input_is_exhausted
    calls = Array.new
    reader do |r|
      r.prepare { (1..3).to_a }
      r.read    { |data|
        calls << :read
        data.shift
      }
      r.finish  { calls << :finish }
    end
    5.times do
      @reader.read
    end
    assert_equal([:read, :read, :read, :read, :finish], calls)
  end
  
  #######
  private
  #######
  
  def reader(&init)
    @reader = Mungr::Reader.new(&init)
  end
end
