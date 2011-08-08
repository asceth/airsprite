module Airsprite
  module Config

    CONFIG_FILENAME="airsprite.yml"


    module ModuleMethods
      def path=(value)
        @@path = value
      end
      def path
        @@path
      end

      def scales=(value)
        @@scales = value
      end
      def scales
        @@scales
      end

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
