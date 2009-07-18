# encoding: UTF-8

require "minitest/autorun"

class MiniTest::Unit::TestCase
  #######
  private
  #######
  
  def reader(*inputs, &init)
    unless inputs.empty?
      return reader do |r|
        r.read { inputs.shift }
      end
    end
    @reader = Mungr::Reader.new(&init)
  end
  
  def munger(&init)
    @munge = Mungr::Munge.new(&init)
  end
  
  def munge(&transform)
    munger do |m|
      m.munge { |_, *data| transform[*data] }
    end
  end
  
  def writer(&init)
    if init.nil?
      return writer do |w|
        w.write { }
      end
    end
    @writer = Mungr::Writer.new(&init)
  end
end
