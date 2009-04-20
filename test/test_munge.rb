# encoding: UTF-8

require "helper"

require "mungr/munge"

class TestMunge < MiniTest::Unit::TestCase
  ##############
  ### Status ###
  ##############
  
  def test_a_munge_is_prepared_before_the_first_munge
    order = Array.new
    munge do |m|
      m.prepare { order << :prepared }
      m.munge   do
        order << :munge
      end
    end
    add_reader(:data)
    assert(!@munge.prepared?, "The Munge was prepared?() before the munge().")
    @munge.munge
    assert( @munge.prepared?,
            "The Munge was not prepared?() after the munge()." )
    assert_equal([:prepared, :munge], order)
  end
  
  def test_exhausting_all_readers_sets_finished
    [ [ ],  # no readers
      [[1, 2, 3]],
      [[1], [1, 2, 3], [1, 2]] ].each do |test_readers|
      order = Array.new
      munge do |m|
        m.munge  do
          order << :munge
        end
        m.finish do
          order << :finish
        end
      end
      test_readers.each do |reader|
        add_reader(*reader)
      end
      assert( !@munge.finished?,
              "The Munge was finished?() before being exhausted." )
      finish
      assert( @munge.finished?,
              "The Mung was not finished?() after being exhausted." )
      assert_equal( [:munge] * (test_readers.map(&:size).max || 0) + [:finish],
                    order )
    end
  end
  
  ###############
  ### Context ###
  ###############
  
  def test_any_value_returned_from_prepare_is_forwarded_to_munge_and_finish
    object = Object.new
    calls  = Array.new
    munge do |m|
      m.prepare { object }
      m.munge   do |context, _|
        calls << context
      end
      m.finish  do |context|
        calls << context
      end
    end
    add_reader(:data)
    finish  # trigger munge and finish code
    assert_equal([object] * 2, calls)
  end
  
  ########################
  ### Managing Readers ###
  ########################
  
  def test_add_reader_associates_input_sources_for_the_munge
    args = Array.new
    munge do |m|
      m.munge do |_, i, l|
        args << [i, l]
      end
    end
    add_reader(1, 2)
    add_reader(:a, :b, :c)
    finish
    assert_equal([[1, :a], [2, :b], [nil, :c]], args)
  end
  
  def test_adding_a_munge_after_a_reader_is_an_error
    munge
    add_reader                             # add a normal Reader
    assert_raises(RuntimeError) do
      @munge.add_reader(Mungr::Munge.new)  # add a Munge
    end
  end
  
  def test_adding_any_kind_of_reader_after_a_munge_is_an_error
    munge
    @munge.add_reader(Mungr::Munge.new)    # add a Munge
    assert_raises(RuntimeError) do
      @munge.add_reader(Mungr::Munge.new)  # can't add another
    end
    assert_raises(RuntimeError) do
      add_reader                           # not even a normal Reader
    end
  end
  
  ########################
  ### Managing Writers ###
  ########################
  
  def test_add_writer_associates_output_sources_for_the_munge
    args = Array.new
    munge do |m|
      m.munge do |_, i|
        i
      end
    end
    add_reader(1, 2, 3)
    add_writer do |w|
      w.write do |_, i|
        args << [:writer1, i]
      end
    end
    add_writer do |w|
      w.write do |_, i|
        args << [:writer2, i]
      end
    end
    finish
    assert_equal( [ [:writer1, 1], [:writer2, 1],
                    [:writer1, 2], [:writer2, 2],
                    [:writer1, 3], [:writer2, 3] ], args )
  end
  
  def test_a_munge_with_a_writer_cannot_be_used_as_a_reader
    chain = munge
    add_writer  # can no longer be used as a Reader
    munge
    assert_raises(RuntimeError) do
      @munge.add_reader(chain)
    end
  end
  
  ###############
  ### Munging ###
  ###############
  
  def test_calling_munge_a_with_block_sets_the_code_and_further_calls_run_it
    data    = (1..3).to_a
    written = Array.new
    munge do |m|
      m.munge do |_, i|
         i * 2
      end
    end
    add_reader(*data)
    add_writer do |w|
      w.write do |_, i2|
        written << i2
      end
    end
    finish
    assert_equal(data.map { |i| i * 2 }, written)
  end
  
  def test_each_input_is_passed_as_an_argument_to_munge
    args = Array.new
    munge do |m|
      m.munge do |_, i, l|
        args << [i, l]
      end
    end
    add_reader(1, 2, 3)
    add_reader(:a, :b, :c)
    finish
    assert_equal([[1, :a], [2, :b], [3, :c]], args)
  end
  
  def test_each_value_returned_from_munge_is_passed_as_an_argument_to_write
    args = Array.new
    munge do |m|
      m.munge do |_, i|
        [i, i * 2, i * 3]
      end
    end
    add_reader(1, 2, 3)
    add_writer do |w|
      w.write do |_, i, i2, i3|
        args << [i, i2, i3]
      end
    end
    finish
    assert_equal([[1, 2, 3], [2, 4, 6], [3, 6, 9]], args)
  end
  
  def test_when_readers_are_exhausted_no_more_munges_or_writes_are_made
    calls = Array.new
    munge do |m|
      m.munge do
        calls << :munge
      end
    end
    add_reader(1, 2, 3)
    add_writer do |w|
      w.write do
        calls << :write
      end
    end
    10.times do
      @munge.munge
    end
    assert_equal([:munge, :write] * 3, calls)
  end
  
  def test_prepare_is_called_once_before_the_first_munge
    calls = Array.new
    munge do |m|
      m.prepare { calls << :prepare }
      m.munge   do
        calls << :munge
      end
    end
    add_reader(1, 2, 3)
    finish
    assert_equal([:prepare, :munge, :munge, :munge], calls)
  end
  
  def test_finish_is_called_once_when_the_input_is_exhausted
    calls = Array.new
    munge do |m|
      m.munge  do
        calls << :munge
      end
      m.finish do
        calls << :finish
      end
    end
    add_reader(1, 2, 3)
    finish
    assert_equal([:munge, :munge, :munge, :finish], calls)
  end
  
  def test_finish_is_forwarded_to_all_writers
    munge do |m|
      m.munge do
        # do nothing:  just defining some munge code
      end
    end
    add_reader(1, 2, 3)
    add_writer do |w|
      w.write do
        # do nothing:  just defining some write code
      end
    end
    add_writer do |w|
      w.write do
        # do nothing:  just defining some write code
      end
    end
    3.times do
      @munge.munge
    end
    assert( @writers.none?(&:finished?),
            "A Writer was finished before input was exhausted." )
    @munge.munge  # input is exhausted here
    assert( @writers.all?(&:finished?),
            "Writers were not finished after input was exhausted." )
  end
  
  ################
  ### Chaining ###
  ################
  
  def test_a_munge_can_read_form_another_munge
    args  = Array.new
    chain = munge do |m|
      m.munge do |_, i|
        i * 2
      end
    end
    add_reader(1, 2, 3)
    munge do |m|
      m.munge do |_, i2|
        args << i2
      end
    end
    @munge.add_reader(chain)
    finish
    assert_equal([2, 4, 6], args)
  end
  
  def test_a_munge_can_be_a_multireader_source_form_another_munge
    args  = Array.new
    chain = munge do |m|
      m.munge do |_, i|
        [i, i * 2, i * 3]
      end
    end
    add_reader(1, 2, 3)
    munge do |m|
      m.munge do |_, i, i2, i3|
        args << [i, i2, i3]
      end
    end
    @munge.add_reader(chain)
    finish
    assert_equal([[1, 2, 3], [2, 4, 6], [3, 6, 9]], args)
  end
  
  def test_finish_is_forwarded_through_chained_munges
    written =  Array.new
    chain   =  Array.new
    chain   << munge do |m|
      m.munge do |_, i, l|
        [i, i * 2, l]
      end
    end
    chain << add_reader(1, 2, 3).last
    chain << add_reader(:a, :b).last
    chain << munge do |m|
      m.munge do |_, i, i2, l|
        "#{l}: #{i} * 2 = #{i2}"
      end
    end
    @munge.add_reader(chain.first)
    chain << add_writer do |w|
      w.write do |_, str|
        written << str
      end
    end.last
    finish
    assert( chain.all?(&:finished?),
            "Not all elements of the chain finished?()." )
    assert_equal(["a: 1 * 2 = 2", "b: 2 * 2 = 4", ": 3 * 2 = 6"], written)
  end
  
  #######
  private
  #######
  
  def munge(&init)
    @munge = Mungr::Munge.new(&init)
  end
  
  def add_reader(*inputs, &init)
    (@readers ||= Array.new) <<
      ( inputs.empty? ? reader(&init) :
                        reader { |r| r.read { inputs.shift } } ).tap { |r|
        @munge.add_reader(r)
      }
  end
  
  def add_writer(&init)
    (@writers ||= Array.new) << writer(&init).tap { |w| @munge.add_writer(w) }
  end
  
  def finish
    @munge.run
  end
end
