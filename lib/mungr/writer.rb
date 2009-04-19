# encoding: UTF-8

require "mungr/staged"

module Mungr
  # 
  # Objects of this class are the basic unit of output for Mungr scripts.
  # Writing using one of these objects is a four stage process:
  # 
  # 1. A Writer is built and configured
  # 2. The Writer is prepared just before the first write
  # 3. Chunks of data are written to the Writer one by one
  # 4. A final call is made to finish the Writer
  # 
  class Writer < Staged
    #
    # Use the +init+ block to build a Writer by assigning code to each of the
    # three code stages, something like:
    # 
    #   file_writer = Writer.new do |w|
    #     w.prepare {           File.open("my_file.txt", "w") }
    #     w.write   { |f, line| f.puts line                   }
    #     w.finish  { |f|       f.close                       }
    #   end
    # 
    # The prepare() and finish() stages are optional.
    # 
    # Once built, you feed data you wish to output into the write() method and
    # then call finish() when you are done, like this:
    # 
    #   file_writer.write("some data")
    #   file_writer.write("more data")
    #   # ...
    #   file_writer.finish  # signal that we are done writing
    # 
    def initialize(*args, &init)
      @write_code = nil
      
      super
    end
    
    #
    # :call-seq:
    #   write() { |context| code_to_read_one_chunk_of_data() }
    #   write(*output)
    # 
    # If passed a block, this method sets the code that will be used to write a
    # single chunk of output.  The block will also be passed the context
    # returned from prepare().
    # 
    # This method, called without block, is also the primary writing interface.
    # You can just call it repeatedly to output values.
    # 
    def write(*output, &code)
      load_or_run(:write, *output, &code)
    end
    
    #######
    private
    #######
    
    # 
    # This method is the primary interface for writing.  It will:
    # 
    # * Return +nil+ if finished?() is now +true+
    # * Run prepare() unless prepared?() is now +true+
    # * Run the write code to output one chunk of data
    # 
    def run_write_code(*args)
      return if finished?
      prepare unless prepared?
      @write_code[@context, *args]
    end
  end
end
