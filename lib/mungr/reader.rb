# encoding: UTF-8

module Mungr
  # 
  # Objects of this class are the basic unit of input for Mungr scripts.
  # Reading using one of these objects is a four stage process:
  # 
  # 1. An Reader is built and configured
  # 2. The Reader is prepared just before the first read
  # 3. Chunks of data are read from the Reader one by one until a +nil+ is
  #    returned to signal that the input is exhausted
  # 4. The Reader is finished just after a +nil+ is read
  # 
  class Reader
    #
    # Use the +init+ block to build a Reader by assigning code to each of the
    # three code stages, something like:
    # 
    #   file_reader = Reader.new do |r|
    #     r.prepare { File.open("my_file.txt") }
    #     r.read    { |f| f.gets               }
    #     r.finish  { |f| f.close              }
    #   end
    # 
    # All stages are optional, though a Reader isn't too handy without some
    # read() code.
    # 
    # Once built, you generally just call read() as long as it returns non-+nil+
    # data and process the values it returns, like this:
    # 
    #   while line = file_reader.read
    #     # ... work with line here ...
    #   end
    # 
    def initialize(&init)
      @prepare_code = nil
      @context      = nil
      @prepared     = false
      @read_code    = nil
      @read         = false
      @finish_code  = nil
      @finished     = false
      
      init[self] if init
    end
    
    # Returns +true+ if the prepare() code has been run, +false+ otherwise.
    def prepared?
      @prepared
    end
    
    # Returns +true+ if the read() code has been run, +false+ otherwise.
    def read?
      @read
    end
    
    # Returns +true+ if the finish() code has been run, +false+ otherwise.
    def finished?
      @finished
    end
    
    #
    # :call-seq:
    #   prepare() { code_to_run_before_reading() }
    #   prepare()
    # 
    # If passed a block, this method sets the code that will be used to prepare
    # this Reader.  Any value returned by this code will be forwarded to the
    # read() and finish() code and thus essentially becomes the shared context
    # of the reading process.
    # 
    # When called without a block, this method actually runs the previously set
    # code.  This is generally done as needed when you call read() and it's not
    # recommended to call this method yourself.
    # 
    def prepare(&code)
      load_or_run(:prepare, &code)
    end
    
    #
    # :call-seq:
    #   read() { |context| code_to_read_one_chunk_of_data() }
    #   read()
    # 
    # If passed a block, this method sets the code that will be used to read a
    # single chunk of data.  The block will be passed the context returned from
    # prepare().  That code should return a +nil+ when input is exhausted.
    # 
    # This method, called without block, is also the primary reading interface.
    # You can just call it repeatedly until it returns +nil+ to indicate that
    # input is exhausted.
    # 
    def read(&code)
      load_or_run(:read, &code)
    end
    
    #
    # :call-seq:
    #   finish() { |context| code_to_run_after_reading() }
    #   finish()
    # 
    # If passed a block, this method sets the code that will be used to finish
    # this Reader.  The block will be passed the context returned from
    # prepare().  This code is called once after input is exhausted and it gives
    # you a chance to do any needed cleanup.
    # 
    # When called without a block, this method actually runs the previously set
    # code.  This is generally done as needed when you call read() and it's not
    # recommended to call this method yourself.
    # 
    def finish(&code)
      load_or_run(:finish, &code)
    end
    
    #######
    private
    #######
    
    #
    # Provides the dual code setting and running behavior of all three stage
    # methods.  If +code+ is non-+nil+ it will be passed on to load_code(),
    # otherwise +name+ code will be run.
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
    # method returns.  Also sets flips the prepared?() status to +true+.
    # 
    def run_prepare_code
      @context  = @prepare_code[]
      @prepared = true
      @context
    end
    
    # 
    # This method is the primary interface for reading.  It will:
    # 
    # * Return +nil+ if read?() is now +true+
    # * Run prepare() unless prepared?() is now +true+
    # * Run the read code to generate one chunk of data and return that result
    # * Run finish() just before returning the first +nil+
    # 
    def run_read_code
      return nil if read?
      prepare unless prepared?
      @read_code[@context].tap { |this_read|
        if this_read.nil?
          @read = true
          finish
        end
      }
    end
    
    #
    # Executes the finish code.  Also sets flips the finished?() status to
    # +true+.
    # 
    def run_finish_code
      @finish_code[@context].tap { @finished = true }
    end
  end
end
