# encoding: UTF-8

require "minitest/autorun"

class MiniTest::Unit::TestCase
  #######
  private
  #######
  
  def reader(&init)
    @reader = Mungr::Reader.new(&init)
  end
  
  def writer(&init)
    @writer = Mungr::Writer.new(&init)
  end
end
