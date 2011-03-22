module Airsprite
  module Base
    def run
      Airsprite::Config.parse_config_file
      @sheets = []

      # each directory underneath Airsprite::Config.path is a sheet
      Dir["#{Airsprite::Config.path}/*/"].each do |dir|
        @sheets << SpriteSheet.new(dir.gsub('/', ''), "#{Airsprite::Config.path}/#{dir}")
      end
    end

    def twos
      [
       2,
       4,
       8,
       16,
       32,
       64,
       128,
       256,
       512,
       1024,
       2048
      ]
    end
  end
  extend Base
end

module Airsprite
  class SpriteSheet
    attr_accessor :name, :path, :sprites

    def initialize(name, directory)
      self.name = name
      self.path = directory
      sprites = []

      Dir["#{self.path}*/"].each do |dir|
        Sprite.new(self, "#{self.path}#{dir}", dir.gsub('/', ''))
      end

      Dir["#{self.path}*.png"].each do |file|
        Sprite.new(self, "#{self.path}#{file}", file.gsub('.png', ''))
      end
    end

    def output
      # figure out lowest possible power of 2
      total_surface = sprites.map(&:area).sum
      max_side = [sprites.map(&:width), sprites.map(:height)].flatten.sort.last
      width = 0
      height = 0

      Airsprite.twos.map do |power_of_two|
        # lowest two must be >= biggest sprite size
        next unless power_of_two >= max_side

        if (total_surface / power_of_two) <= power_of_two
          width = power_of_two
          height = Airsprites.twos[Airsprite.twos.index(power_of_two) - 1]
          break
        end
      end

      # set these sprite frames up!
      frames = sprites.map(&:animations).flatten.map(&:frames).flatten.sort_by(&:area)
      rects = [Rect.new(width, height, 0, 0)]

      # place frames
      frames.map do |frame|
        # find first square that can contain this sprite
        raise "No rects left to fill" if rects.empty?

        rects.map do |rect|
          if rect.area >= frame.area
            frame.x = rect.x
            frame.y = rect.y

            # delete rect from list
            rects.delete(rect)
            unless rect.height == frame.height && rect.width == frame.width
              if rect.height == frame.height
                rects << Rect.new(rect.width - frame.width, rect.height, rect.x + frame.width, rect.y)
              elsif rect.width == frame.width
                rects << Rect.new(rect.width, rect.height - frame.height, rect.x, rect.y + frame.height)
              else
                rects << Rect.new(frame.width, rect.height - frame.height, rect.x, rect.y + frame.height)
                rects << Rect.new(rect.width - frame.width, rect.height, rect.x + frame.width, rect.y)
              end
            end
            break
          end
        end
      end

      image = Magick::Image.new(width, height)

      frames.map do |frame|
        image.store_pixels(frame.x, frame.y, frame.width, frame.height, frame.data.get_pixels(0, 0, frame.width, frame.height))
      end
      image.write("#{self.path}#{self.name}.png")
    end
  end

  class Square
    attr_accessor :width, :height, :x, :y

    def initialize(width, height, offset_x, offset_y)
      self.width = width
      self.height = height
      self.x = offset_x
      self.y = offset_y
    end

    def area
      width * height
    end
  end

  class Sprite
    attr_accessor :sheet, :name
    attr_accessor :animations

    def initialize(sheet, path, name)
      self.name = name
      animations = []

      if File.directory?(path)
        Dir["#{path}*/"].each do |dir|
          animation = Animation.new(dir.gsub('/', ''), "#{path}#{dir}")
          animations << animation
        end
      else
        animation = Animation.new('idle')
        animation.frames << Frame.new(name, path)
        animations << animation
      end

      if animations.map(&:frames).flatten.map(&:width).uniq.size > 1
        raise "Widths of frames for a sprite must be the same width"
      end

      if animations.map(&:frames).flatten.map(&:height).uniq.size > 1
        raise "Widths of frames for a sprite must be the same height"
      end
    end
  end

  class Animation
    attr_accessor :name
    attr_accessor :frames

    def initialize(name, path)
      self.name = name
      frames = []

      if File.directory?(path)
        Dir["#{path}*.png"].each do |file|
          frames << Frame.new(file.gsub('/', ''), "#{path}#{file}")
        end
      else
        frames << Frame.new(name, path)
      end
    end
  end

  class Frame
    attr_accessor :name, :data, :width, :height, :area, :x, :y

    def initialize(name, path)
      self.name = name
      self.data = Magick::Image::read(path).first
      self.width = self.data.x_resolution.to_i
      self.height = self.data.y_resolution.to_i
      self.area = self.width * self.height
    end
  end
end

