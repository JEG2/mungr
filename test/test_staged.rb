# encoding: UTF-8

require "minitest/autorun"

require "mungr/staged"

class TestStaged < MiniTest::Unit::TestCase
  ##############
  ### Stages ###
  ##############
  
  def test_prepare_sets_or_runs_code
    assert_stage_sets_or_runs_code(:prepare)
  end
  
  def test_finish_sets_or_runs_code
    assert_stage_sets_or_runs_code(:prepare)
  end
  
  ##############
  ### Status ###
  ##############
  
  def test_a_new_staged_object_is_not_prepared_or_finished
    staged
    assert(!@staged.prepared?, "A new Staged was already prepared?().")
    assert(!@staged.finished?, "A new Staged was already finished?().")
  end
  
  def test_prepare_sets_prepared_with_or_without_code
    assert_stage_flagged_with_and_without_code(:prepare)
  end
  
  def test_finished_sets_finished_with_or_without_code
    assert_stage_flagged_with_and_without_code(:finish)
  end
  
  #######
  private
  #######
  
  def staged(&init)
    @staged = Mungr::Staged.new(&init)
  end
  
  def assert_stage_sets_or_runs_code(stage)
    staged
    assert_nil(@staged.send(stage))                     # no code defined
    flag = "test_#{stage}_code_run"
    assert_same(@staged, @staged.send(stage) { flag })  # sets code
    assert_equal(flag, @staged.send(stage))             # runs code
  end
  
  def assert_stage_flagged_with_and_without_code(stage)
    flag = stage.to_s.sub(/e?\z/, "ed?")
    staged do |s|
      s.send(stage) { :some_code }
    end
    assert( !@staged.send(flag),
            "The Staged object was #{flag}() before being called." )
    @staged.send(stage)
    assert( @staged.send(flag),
            "The Staged object was not #{flag}() after being called." )
    staged  # no code
    assert( !@staged.send(flag),
            "The Staged object was #{flag}() before being called." )
    @staged.send(stage)
    assert( @staged.send(flag),
            "The Staged object was not #{flag}() after being called." )
  end
end
