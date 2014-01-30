require "scrolls"
require "thread"

module Yawl
  module Log
    extend self

    def elapsed_since(t0)
      "%dms" % (Time.now - t0)
    end

    def log_measure(data)
      if Config.app
        measure_base = "#{Config.app}.#{data[:ns]}.#{data[:fn]}"
      else
        measure_base = "#{data[:ns]}.#{data[:fn]}"
      end

      begin
        t0 = Time.now
        log(data.merge(at: "start"))
        log_control = OpenStruct.new(data.merge(finish_at: "finish"))
        result = yield(log_control)
        log(data.merge("measure##{measure_base}.#{log_control.finish_at}" => elapsed_since(t0), at: log_control.finish_at))
        result
      rescue => error
        log(data.merge("measure##{measure_base}.exception" => elapsed_since(t0), at: "exception", "class" => error.class, message: error.message))
        raise error
      end
    end

    def log(data, &block)
      if Config.log_quiet?
        block.call if block
      else
        params = { }
        params[:app] = Config.app if Config.app
        params[:source] = Config.deploy if Config.deploy
        Scrolls.log(params.merge(data), &block)
      end
    end
  end
end
