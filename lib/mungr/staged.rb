# encoding: UTF-8

module Mungr
  # 
  # A Staged object is an object that is prepared, executed, and finished.  The
  # main execution stage is not included by this class and it is up to
  # subclasses to tie things together.  This object does provide the
  # constructing, preparing, and finishing infrastructure.
  # 
  class Staged
    #
    # Staged objects are never constructed directly.  See the subclasses for
    # details of how they are bult.
    # 
    def initialize(&init)
      @prepare_code = nil
      @context      = nil
      @prepared     = false
      @finish_code  = nil
      @finished     = false
      
      init[self] if init
    end
    
    # Returns +true+ if the prepare() code has been run, +false+ otherwise.
    def prepared?
      @prepared
    end
    
    # Returns +true+ if the finish() code has been run, +false+ otherwise.
    def finished?
      @finished
    end
    
    #
    # :call-seq:
    #   prepare() { code_to_run_first() }
    #   prepare()
    # 
    # If passed a block, this method sets the code that will be used to prepare
    # this object.  Any value returned by this code will be forwarded to the
    # later stages and thus essentially becomes the shared context of the
    # Staged process.
    # 
    # When called without a block, this method actually runs the previously set
    # code.  This is generally done as needed when you call a later stage and
    # it's not recommended to call this method yourself.
    # 
    def prepare(&code)
      load_or_run(:prepare, &code)
    end
    
    #
    # :call-seq:
    #   finish() { |context| code_to_run_last() }
    #   finish()
    # 
    # If passed a block, this method sets the code that will be used to finish
    # this object.  The block will be passed the context returned from
    # prepare().  This code is called once after the main stage completes giving
    # you a chance to do any needed cleanup.
    # 
    # When called without a block, this method actually runs the previously set
    # code.  This is generally done as needed as you run the main stage and it's
    # not recommended to call this method yourself.
    # 
    def finish(&code)
      load_or_run(:finish, &code)
    end
    
    #######
    private
    #######
    
    #
    # Provides the dual code setting and running behavior of all stage methods.
    # If +code+ is non-+nil+ it will be passed on to load_code(), otherwise
    # +name+ code will be run.
    # 
    def load_or_run(name, &code)
      if code
        load_code(name, code)
      elsif instance_variable_get("@#{name}_code")
        send("run_#{name}_code")
      end
    end
    
    #
    # Sets an instance variable based on +name+ to hold +code+ for later use.
    # Also returns +self+ for method chaining.
    # 
    def load_code(name, code)
      instance_variable_set("@#{name}_code", code)
      self
    end
    
    #
    # Executes the prepare code, saving and returning the shared context that
    # method returns.  Also flips the prepared?() status to +true+.
    # 
    def run_prepare_code
      @context  = @prepare_code[]
      @prepared = true
      @context
    end
    
    #
    # Executes the finish code.  Also flips the finished?() status to +true+.
    # 
    def run_finish_code
      @finish_code[@context].tap { @finished = true }
    end
  end
end
