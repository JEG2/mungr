# encoding: UTF-8

require "mungr/dsl"

include Mungr::DSL
at_exit do
  mungr_job.build.run
end
