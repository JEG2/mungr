# encoding: UTF-8

require "mungr/job"

module Mungr
  module DSL
    def mungr_job
      @mungr_job ||= Job.new
    end
    
    def reader(&init)
      mungr_job << Reader.new(&init)
    end
    
    def munger(&init)
      mungr_job << Munge.new(&init)
    end
    
    def munge(&transform)
      munger do |m|
        m.munge { |_, *data| transform[*data] }
      end
    end
    
    def writer(&init)
      mungr_job << Writer.new(&init)
    end
  end
end
