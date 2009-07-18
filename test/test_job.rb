# encoding: UTF-8

require "helper"

require "mungr/job"

class TestJob < MiniTest::Unit::TestCase
  def setup
    reset_job
    
    @small_num_reader = reader(1,  2,  3)
    @big_num_reader   = reader(10, 20, 30)
    @add_one_munge    = munge { |*nums| nums.map { |n| n + 1 } }
    @double_munge     = munge { |*nums| nums.map { |n| n * 2 } }
    @gather_writer    = writer do |w|
      w.prepare {                   @gathered =  Array.new }
      w.write   { |gathered, *nums| gathered  << nums      }
    end
    @void_writer      = writer

    [ @small_num_reader, @big_num_reader,
      @add_one_munge,
      @double_munge,
      @gather_writer, @void_writer ].each do |reader_or_munge_or_writer|
      @job << reader_or_munge_or_writer
    end
  end
  
  ####################
  ### Requirements ###
  ####################
  
  def test_a_reader_is_required
    reset_job
    assert_raises(RuntimeError) do
      @job.build
    end
  end
  
  def test_a_writer_is_required
    reset_job
    @job << @small_num_reader
    assert_raises(RuntimeError) do
      @job.build
    end
  end
  
  def test_a_munge_is_optional_with_a_pass_through_default
    reset_job
    @job  << reader(:pass_through)
    @job  << @void_writer
    munge =  @job.build
    assert_instance_of(Mungr::Munge, munge)
    assert_equal(:pass_through, munge.munge)
  end
  
  #################
  ### Interface ###
  #################
  
  def test_cannot_add_a_non_reader_non_munge_non_writer_object
    assert_raises(RuntimeError) do
      @job << :bad_object
    end
  end
  
  def test_adds_can_be_chained
    assert_same(@job, @job << @void_writer)
  end
  
  #################
  ### Structure ###
  #################
  
  def test_the_last_munge_is_returned
    assert_same(@double_munge, @job.build)
  end
  
  def test_readers_feed_chained_mungers_which_feed_writers
    @job.build.run
    assert_equal([[4, 22], [6, 42], [8, 62]], @gathered)  # verify final results
  end
  
  #######
  private
  #######
  
  def reset_job
    @job = Mungr::Job.new
  end
end
