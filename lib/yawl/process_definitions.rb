module Yawl
  module ProcessDefinitions
    def self.[](name)
      all[name.to_sym]
    end

    def self.add(name, &block)
      all[name.to_sym] = block
    end

    def self.all
      @all ||= {}
    end

    def self.all_names
      all.keys.map {|k| k.to_s }
    end

    def self.realize_on(name, process)
      unless definition = self[name]
        raise "Can't find definition #{name}"
      end

      definition.call(process)
    end
  end
end
