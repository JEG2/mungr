# encoding: UTF-8

require "mungr/reader"
require "mungr/munge"
require "mungr/writer"

module Mungr
  # 
  # A Job object is used to gather Reader, Munge, and Writer objects as a
  # munging process is defined.  After all elements of the process have been
  # gathered, this Job is used to build() the correct object tree which can be
  # used to run() the process.
  # 
  class Job
    # 
    # Creates an empty Job.  You then add Readers, Munges, and Writers needed
    # and build() the final process.  This generally looks something like the
    # following:
    # 
    #   job    = Job.new
    #   reader = Reader.new do |r|
    #     # ...
    #   end
    #   munge  = Munge.new do |m|
    #     # ...
    #   end
    #   writer = Writer.new do |w|
    #     # ...
    #   end
    #   job << reader << munge << writer
    #   job.build.run
    # 
    def initialize
      @readers = Array.new
      @munges  = Array.new
      @writers = Array.new
    end
    
    #
    # Adds a Reader, Munge, or Writer that will become a part of the final
    # munging process.
    # 
    def <<(reader_or_munge_or_writer)
      case reader_or_munge_or_writer
      when Reader
        @readers << reader_or_munge_or_writer
      when Munge
        @munges << reader_or_munge_or_writer
      when Writer
        @writers << reader_or_munge_or_writer
      else
        fail "You must add a Reader, Munge, or Writer."
      end
      self  # for chaining
    end
    
    #
    # Constructs the final object tree for the munging process using all
    # gathered Readers, Munges, and Writers.
    # 
    # All Readers will be registered, in the order they are added, on the first
    # Munge added.  All Writers will be registered, in the order they are added,
    # on the last Munge added.  All Munges added are chained such that the first
    # Munge added will be at the top of the chain and last Munge added will be
    # at the bottom.  The last Munge is returned so you can call run() on it to
    # start the process.
    # 
    # Adding a Munge is optional and a simple pass-through Munge will be created
    # and returned (with all Readers and Writers attached), if none is added.
    # 
    def build
      fail "You need at least one Reader to build a Job." if @readers.empty?
      fail "You need at least one Writer to build a Job." if @writers.empty?
      if @munges.empty?
        first_munge = last_munge = Munge.new do |m|
          m.munge { |_, value| value }
        end
      else
        first_munge = last_munge = @munges.pop
        while munge_as_reader = @munges.pop
          first_munge.add_reader(munge_as_reader)
          first_munge = munge_as_reader
        end
      end
      @readers.each do |reader|
        first_munge.add_reader(reader)
      end
      @writers.each do |writer|
        last_munge.add_writer(writer)
      end
      last_munge
    end
  end
end
