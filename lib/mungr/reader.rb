# encoding: UTF-8

require "mungr/staged"

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
  class Reader < Staged
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
    # The prepare() and finish() stages are optional.
    # 
    # Once built, you generally just call read() as long as it returns non-+nil+
    # data and process the values it returns, like this:
    # 
    #   while line = file_reader.read
    #     # ... work with line here ...
    #   end
    # 
    def initialize(*args, &init)
      @read_code = nil
      
      super
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
    
    #######
    private
    #######
    
    # 
    # This method is the primary interface for reading.  It will:
    # 
    # * Return +nil+ if finished?() is now +true+
    # * Run prepare() unless prepared?() is now +true+
    # * Run the read code to generate one chunk of data and return that result
    # * Run finish() just before returning the first +nil+
    # 
    def run_read_code
      return nil if finished?
      prepare unless prepared?
      @read_code[@context].tap { |this_read| finish if this_read.nil? }
    end
  end
end
