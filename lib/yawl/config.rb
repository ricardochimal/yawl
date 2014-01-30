module Yawl
  module Config
    extend self

    attr_accessor :app
    attr_accessor :deploy

    def log_quiet?
      env("LOG_QUIET") == "1"
    end

    def log_sequel?
      env("LOG_SEQUEL") == "1"
    end

    def env(key)
      ENV[key]
    end

    def env!(key)
      ENV[key] or raise "Missing ENV[#{key}]"
    end
  end
end
