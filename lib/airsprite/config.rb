module Airsprite
  module Config

    CONFIG_FILENAME="airsprite.yml"

    mattr_accessor :scales, :path

    module ModuleMethods
      def parse_config_file
        self.path = Dir.pwd

        if File.exists?(CONFIG_FILENAME)
          YAML.load(File.read(CONFIG_FILENAME)).each {|(name, value)| send "#{name}=", value }
        else
          self.scales          = [1.0]
        end
      end
    end
    extend ModuleMethods
  end
end
