class BitmapEditor
  # attr_accessible :title, :body

  attr_reader :commands, :bitmap, :file_path

  DEFAULT_BLOCK_COLOR = 'O'.freeze
  COMMAND_DELIMITER = ' '.freeze
  SUPPORTED_COMMANDS = %w(I C L V H S).freeze
  MAX_PIXEL =250
  MIN_PIXEL=1
  error_log = File.open("error_log.txt", "w")

  def initialize(file_path)
    @file_path = file_path
    @commands = Hash.new
    @bitmap = nil
  end

  def start
    if not file_present?
      File.open("error_log.txt", "w") { |file| file.puts "Commands file not present at #{file_path}"}
      return
    end

    bitmap_width=bitmap.first.size
    bitmap_height=bitmap.size

    @commands_hash = get_commands
    @commands_hash.each_with_index do |(command_key, arguments_array), index|
      draw_bitmap(command_key,arguments_array) if check_validity(command_key,arguments_array,index) && !command_key.nil?
    end
  end

  def check_validity(command_key,arguments_array, i)
    #arguments_array = command.argument_string.strip.split(COMMAND_DELIMITER)
    arguments_array.compact!
    arguments_array.reject { |e| e.to_s.empty? }
    verified_arguments = verify_arguments( command_key, arguments_array,i)
    verified_arguments && SUPPORTED_COMMANDS.include?(command_key)
  end

  def verify_arguments(command_key,arguments_array,i)
    case command_key
      when 'I' then
        if not check_arguments_length(arguments_array, 2)
          write_to_log(i,"Command key I requires 2 paramenters")
          return false
        end
        if check_arguments_numericality(arguments_array)
          write_to_log(i,"Command key I requires all paramenters to be numeric")
          return false
        end
        if not check_pixels_range arguments_array
          write_to_log(i,"Pixels value out of valid range")
          return false
        end
      when 'L' then
        if not check_arguments_length(arguments_array, 3)
          write_to_log(i,"Command key L requires 3 parameters")
          return false
        end
        if not is_string?(arguments_array[2])
          write_to_log(i,"Third parameter with Command key L should not be numeric")
          return false
        end
        if not check_pixels_range arguments_array.take(2)
          write_to_log(i,"Pixels value out of valid range")
          return false
        end
      when 'V' then
        if not check_arguments_length(arguments_array, 4)
          write_to_log(i,"Command key V requires 4 parameters")
          return false
        end
        if not is_string?(arguments_array[3])
          write_to_log(i,"Fourth parameter with Command key V should not be numeric")
          return false
        end
        if not check_pixels_range arguments_array.take(3)
          write_to_log(i,"Pixels value out of valid range")
          return false
        end
      when 'H' then
        if not check_arguments_length(arguments_array, 4)
          write_to_log(i,"Command key H requires 4 parameters")
          return false
        end
        if not is_string?(arguments_array[3])
          write_to_log(i,"Fourth parameter with Command key H should not be numeric")
          return false
        end
        if not check_pixels_range arguments_array.take(3)
          write_to_log(i,"Pixels value out of valid range")
          return false
        end
      when 'C' then
        if not check_arguments_length(arguments_array, 0)
          write_to_log(i,"Command key C does not require any parameters")
          return false
        end
      when 'S' then
        if not check_arguments_length(arguments_array, 0)
          write_to_log(i,"Command key S does not require any parameters")
          return false
        end
    end
  end

  def write_to_log(line,msg)
    File.open("error_log.txt", "w") { |file| file.puts "Line #{line} : #{msg}"}
  end

  def check_arguments_length(arguments_array,length)
    arguments.length == length
  end

  def check_arguments_numericality(arguments_array)
    arguments_array.all? { |x| x.to_f == x }
  end

  def check_pixels_range arguments_array
    arguments_array.all? { |x| x >=MIN_PIXEL and x <= MAX_PIXEL }
  end

  def is_string?(string)
    string.to_s.upcase != string.to_s.downcase
  end

  def file_present?
    !file_path.empty? && File.exist?(file_path)
  end

  def get_commands
    command_hash= Hash.new { |k, v| k[v] = [] }
    File.open(file_path).each_with_index.map do |line, index|
      line_array= line.chomp.split(COMMAND_DELIMITER)
      command_key = line_array[0]
      command_hash[command_key]= line_array.drop(1)
    end
    return command_hash
  end

  private

  def draw_bitmap(command_key,arguments_array)
    case command_key
      when 'I' then create_bitmap(arguments_array)
      when 'L' then colour_pixel(arguments_array)
      when 'V' then draw_vertical_line(arguments_array)
      when 'H' then draw_horizontal_line(arguments_array)
      when 'C' then clear_bitmap
      when 'S' then show_bitmap
    end
  end

  def create_bitmap(arguments_array)
    height = arguments_array[0]
    width = arguments_array[1]
    @bitmap = Array.new(height) { Array.new(width, DEFAULT_BLOCK_COLOR) }
  end

  def colour_pixel(arguments_array)
    return if @bitmap.nil?
    pixel_x=arguments_array[0]
    pixel_y=arguments_array[1]
    color=arguments_array[2]
    return unless inside_bitmap_area?(x: pixel_x, y: pixel_y)
    lower_x = get_lower_value(pixel_x, bitmap_width)
    lower_y = get_lower_value(pixel_y, bitmap_height)
    @bitmap[lower_y][lower_x] = color
  end

  def draw_vertical_line(arguments_array)
    return if @bitmap.nil?
    coordinate_x=arguments_array[0]
    y_start_point=arguments_array[1]
    y_end_point=arguments_array[2]
    color=arguments_array[3]
    return unless inside_bitmap_area?(x: coordinate_x, y: y_start_point, y2: y_end_point)
    lower_x = get_lower_value(x, bitmap_width)
    for y in y_end_point..y_end_point
      lower_y = get_lower_value(y, bitmap_height)
      @bitmap[lower_y][lower_x] = color
    end
  end

  def draw_horizontal_line(arguments_array)
    return if @bitmap.nil?
    coordinate_y=arguments_array[0]
    x_start_point=arguments_array[1]
    x_end_point=arguments_array[2]
    color=arguments_array[3]
    return unless inside_bitmap_area?(x: x_start_point, x2: x_end_point, y: coordinate_y)
    lower_y = get_lower_value(coordinate_y, bitmap_height)
    for x in x_start_point..x_end_point
      lower_x = get_lower_value(x, bitmap_width)
      @bitmap[lower_y][lower_x] = color
    end
  end

  def clear_bitmap
    return if @bitmap.nil?
    for i in 0..bitmap_width
      for j in 0..bitmap_height
        @bitmap[i][j] = DEFAULT_BLOCK_COLOR
      end
    end
  end

  def show_bitmap
    return puts("No bitmap created yet") if @bitmap.nil?
    puts @bitmap.map { |row| row.join }.join("\n")
  end

  def get_lower_value(coordinate, boundary)
    (coordinate > boundary ? boundary : coordinate) - 1
  end

  def inside_bitmap_area?(x:, y:, x2: nil, y2: nil)
    if x2
      (x <= bitmap_width || x2 <= bitmap_width) && y <= bitmap_height
    elsif y2
      x <= bitmap_width && (y <= bitmap_height || y2 <= bitmap_height)
    else
      x <= bitmap_width && y <= bitmap_height
    end
  end
end
