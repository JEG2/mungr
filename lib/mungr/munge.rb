# encoding: UTF-8

require "mungr/staged"

module Mungr
  # 
  # Objects of this class are the basic unit of transformation for Mungr
  # scripts.  Altering some data using one of these objects is a five stage
  # process:
  # 
  # 1. A Munge is built and configured
  # 2. Readers and Writers are added to the Munge or it is chained to another
  #    Munge
  # 3. The Munge is prepared just before the first munge
  # 4. Chunks of data are read from the attached Readers, transformed by the
  #    munge code, and passed on in modified form to the attached Writers
  # 5. The Munge and all attached Writers are finished when all Readers are
  #    exhausted
  # 
  class Munge < Staged
    #
    # Use the +init+ block to build a Munge by assigning code to each of the
    # three code stages, something like:
    # 
    #   doubler = Munge.new do |m|
    #     m.prepare {
    #       # if needed...
    #     }
    #     m.munge   do |context_from_prepare, value|
    #       value * 2
    #     end
    #     m.finish  do |context_from_prepare|
    #       # if needed...
    #     end
    #   end
    # 
    # The prepare() and finish() stages are optional.
    # 
    # Once built, you attach Readers and Writers then call munge() repeatedly to
    # process the data in chunks or just call run() once to exhaust all data,
    # like this:
    # 
    #   numbers = Reader.new do |r|
    #     r.prepare {
    #       (1..100).to_a
    #     }
    #     r.read    { |ns|
    #       ns.shift
    #     }
    #   end
    #   doubler.add_reader(numbers)
    #   
    #   file_writer = Writer.new do |w|
    #     w.prepare {
    #       File.open("doubled_numbers.txt", "w")
    #     }
    #     w.write   do |f, double|
    #       f.puts double
    #     end
    #     w.finish  do |f|
    #       f.close
    #     end
    #   end
    #   doubler.add_writer(file_writer)
    # 
    #   doubler.run
    # 
    def initialize(*args, &init)
      @readers    = Array.new
      @munge_code = nil
      @writers    = Array.new
      
      super
    end
    
    #
    # :call-seq:
    #   add_reader(reader)
    #   add_reader(munge)
    # 
    # This method can be used to attach one or more Readers to this object.
    # Input will be fetched from all Readers with each call to munge() and
    # passed as arguments to the munge code.  When all Readers are exhausted,
    # this object will be marked finished?() as will all attached Writers.
    # 
    # Alternately, you may set a single Munge (not combined with anything else)
    # as the Readers for this object.  All values returned by a call to the
    # chained munge() will be treated as inputs for this object's munge code.
    # 
    # Returns +self+ for method chaining.
    # 
    def add_reader(reader_or_munge)
      fail "Already reading from a Munge." if @readers.is_a? self.class
      case reader_or_munge
      when self.class
        if @readers.empty?
          fail "A Munge used as a Reader cannot have Writers." \
            if reader_or_munge.has_writers?
          @readers = reader_or_munge
        else
          fail "Cannot mix Readers with a Munge."
        end
      else
        @readers << reader_or_munge
      end
      self
    end
    
    # 
    # This method can be used to attach one or more Writers to this object.
    # All values returned by the munge code are passed on as arguments to a
    # write call for each attached Writer.  Furthermore, finish() is called on
    # all attached Writers when input is exhausted.
    # 
    def add_writer(writer)
      @writers << writer
      self
    end
    
    #
    # Returns +true+ if this object has an attached Writers, +false+ otherwise.
    # This object can not be chained as the Readers of another Munge if it was
    # any Writers attached.
    # 
    def has_writers?
      not @writers.empty?
    end
    
    #
    # :call-seq:
    #   munge() { |context, data| code_to_transform_one_chunk_of_data(data) }
    #   munge(*input)
    # 
    # If passed a block, this method sets the code that will be used to
    # transform a single chunk of input.  The altered values returned from this
    # block will be passed on to all attached Writers as output.  The block will
    # also be passed the context returned from prepare().
    # 
    # This method, called without block, is also the primary interface for a
    # munging process.  You can just call it repeatedly to read from attached
    # Readers, transform data, and output values.
    # 
    def munge(&code)
      load_or_run(:munge, &code)
    end
    
    # Calls munge() repeatedly until finished?() returns +true+.
    def run
      munge until finished?
    end
    
    #######
    private
    #######
    
    # 
    # This method is the primary interface for transforming data.  It will:
    # 
    # * Return +nil+ if finished?() is now +true+
    # * Run prepare() unless prepared?() is now +true+
    # * Run the munge code to transform one chunk of data, pass the transformed
    #   data to all attached Writers, as well as return it
    # * Run finish() on this object and all attached Writers after all attached
    #   Readers are exhausted
    # 
    def run_munge_code
      return nil if finished?
      prepare unless prepared?
      inputs = @readers.is_a?(self.class) ? @readers.munge :
                                            @readers.map(&:read)
      if Array(@readers).all?(&:finished?)
        finish
        @writers.each(&:finish)
      else
        outputs = @munge_code[@context, *inputs]
        @writers.each do |writer|
          writer.write(*outputs)
        end
        outputs
      end
    end
  end
end
