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
  
  ######################
  ### Adding a Stage ###
  ######################
  
  def test_forwarding_to_load_or_run_adds_a_stage
    test_staged = subclass do
      def test(&code)
        load_or_run(:test, &code)
      end
      
      private
      
      def run_test_code
        @test_code[]
      end
    end
    flag = :ran_test_code
    staged(test_staged) do |s|
      s.test { flag }
    end
    assert_equal(flag, @staged.test)
  end
  
  def test_a_stage_can_support_arguments_when_run
    test_args_staged = subclass do
      def test_with_args(*args, &code)
        load_or_run(:test_with_args, *args, &code)
      end
      
      private
      
      def run_test_with_args_code(*args)
        @test_with_args_code[*args]
      end
    end
    staged(test_args_staged) do |s|
      s.test_with_args { |*args| args }
    end
    assert_equal([ ],    @staged.test_with_args)
    assert_equal([1],    @staged.test_with_args(1))
    assert_equal([1, 2], @staged.test_with_args(1, 2))
  end
  
  #######
  private
  #######
  
  def staged(staged_class = Mungr::Staged, &init)
    @staged = staged_class.new(&init)
  end
  
  def subclass(&class_def)
    Class.new(Mungr::Staged, &class_def)
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
