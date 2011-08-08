module Airsprite
  module Base
    def run
      Airsprite::Config.parse_config_file

      # each directory underneath Airsprite::Config.path is a sheet
      Dir["#{Airsprite::Config.path}/*/"].each do |dir|
        spritesheet = SpriteSheet.new(dir.split('/').last, dir)
        spritesheet.place
        spritesheet.output
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
    attr_accessor :surface, :max_side, :width, :height

    def initialize(name, directory)
      self.name = name
      self.path = directory
      self.sprites = []

      Dir["#{self.path}*/"].each do |dir|
        self.sprites += [Sprite.new(self, dir.split('/').last, dir)]
      end

      Dir["#{self.path}*.png"].each do |file|
        self.sprites += [Sprite.new(self, File.basename(file, '.png'), file)]
      end
    end

    def to_s
      <<-EOS
SpriteSheet
{
  name "#{name}"

#{sprites.map(&:to_s).join}
}
      EOS
    end

    def place
      # biggest first
      frames = sprites.map(&:animations).flatten.map(&:frames).flatten.sort_by(&:area).reverse

      # figure out lowest possible power of 2
      @surface = frames.map(&:area).inject(0) {|sum, area| sum + area}
      @max_side = [frames.map(&:width), frames.map(&:height)].flatten.sort.last
      @width = 0
      @height = 0

      STDERR.puts "surface needed: #{@surface}"
      Airsprite.twos.map do |power_of_two|
        # lowest two must be >= biggest sprite size
        next unless power_of_two >= @max_side

        if (@surface / power_of_two) <= power_of_two
          if (power_of_two * Airsprite.twos[Airsprite.twos.index(power_of_two) - 1]) > @surface
            @width = power_of_two
            @height = Airsprite.twos[Airsprite.twos.index(power_of_two) - 1]
          else
            @width = power_of_two
            @height = power_of_two
          end
          STDERR.puts "surface generated: #{@width * @height}"
          break
        end
      end

      # set these sprite frames up!
      rects = [Rect.new(@width, @height, 0, 0)]

      # place frames
      frames.map do |frame|
        # find first square that can contain this sprite
        raise "No rects left to fill" if rects.empty?

        STDERR.puts "\n\n"
        STDERR.puts frame.to_short_s
        STDERR.puts rects.map(&:to_s).join("\n")
        rects.map do |rect|
          if rect.area >= frame.area && rect.width >= frame.width && rect.height >= frame.height
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
    end

    def output
      frames = sprites.map(&:animations).flatten.map(&:frames).flatten.sort_by(&:area)

      draw = Magick::Draw.new
      image = Magick::Image.new(@width, @height)
      draw.matte(0, 0, Magick::ResetMethod)

      frames.map do |frame|
        next if frame.x.nil? || frame.y.nil?
        #draw.composite(frame.data, frame.x, frame.y, Magick::CopyCompositeOp)
        draw.composite(frame.x, frame.y, frame.width, frame.height, frame.data, Magick::CopyCompositeOp)
        #image.store_pixels(frame.x, frame.y, frame.width, frame.height, frame.data.get_pixels(0, 0, frame.width, frame.height))
      end
      STDERR.puts "writing to #{self.path[0..-2]}.itx"
      File.open("#{self.path[0..-2]}.itx", 'w') {|f| f.write(self.to_s)}
      STDERR.puts "writing to #{self.path[0..-2]}.png"
      image.set_channel_depth(Magick::AllChannels, 8)
      draw.draw(image)
      image.write("#{self.path[0..-2]}.png")
    end
  end

  class Rect
    attr_accessor :width, :height, :x, :y

    def initialize(width, height, offset_x, offset_y)
      @width = width
      @height = height
      @x = offset_x
      @y = offset_y
    end

    def area
      width * height
    end

    def to_s
      "rect: #{width} x #{height} = #{area} (#{x}, #{y})"
    end
  end

  class Sprite
    attr_accessor :sheet, :name
    attr_accessor :animations

    def initialize(sheet, name, path)
      @name = name
      @animations = []

      if File.directory?(path)
        Dir["#{path}*/"].each do |dir|
          @animations += [SpriteAnimation.new(dir.split('/').last, dir)]
        end
      else
        @animations += [SpriteAnimation.new('idle', path)]
      end

      if @animations.map(&:frames).flatten.map(&:width).uniq.size > 1
        raise "Widths of frames for a sprite must be the same width"
      end

      if @animations.map(&:frames).flatten.map(&:height).uniq.size > 1
        raise "Widths of frames for a sprite must be the same height"
      end
    end

    def to_s
      <<-EOS
  Sprite
  {
    name "#{name}"

#{animations.map(&:to_s).join}
  }
      EOS
    end
  end

  class SpriteAnimation
    attr_accessor :name
    attr_accessor :frames

    def initialize(name, path)
      @name = name
      @frames = []

      if File.directory?(path)
        Dir["#{path}*.png"].each do |file|
          @frames << SpriteFrame.new(File.basename(file, '.png'), file)
        end
      else
        @frames << SpriteFrame.new(File.basename(path, '.png'), path)
      end

      @frames.sort_by(&:name).inject(0) do |position, frame|
        frame.position = position
        position + 1
      end
    end

    def to_s
      <<-EOS
    SpriteAnimation
    {
      name "#{name}"

#{frames.sort_by(&:position).map(&:to_s).join}
    }
      EOS
    end
  end

  class SpriteFrame
    attr_accessor :name, :data, :position, :speed
    attr_accessor :width, :height, :area, :x, :y

    def initialize(name, path)
      split_name = name.split('-')

      if split_name.size == 1
        @name = split_name[0]
        @speed = 0
      else
        @name = split_name.shift
        @speed = split_name.join.to_i
      end

      @data = Magick::Image::read(path).first
      @width = @data.columns.to_i
      @height = @data.rows.to_i
      @area = @width * @height
    end

    def to_s
      <<-EOS
      SpriteFrame
      {
        name "#{name}"
        speed #{speed}
        position #{position}
        width #{width}
        height #{height}
        area #{area}
        x #{x}
        y #{y}
      }
      EOS
    end

    def to_short_s
      "frame: #{width} x #{height} = #{area} (#{x}, #{y})"
    end
  end
end

