module Paperclip
  class Cde < Processor

  def initialize(file, options = {},attachment = nil)
    super
    @file = file
    @current_format = File.extname(@file.path)
    @basename = File.basename(@file.path, @current_format)
    # PAWIEN: use default value only if option is not specified
    @white_canvas  = Rails.root.join('public/images/white_canvas.png')
    @current_geometry = Geometry.from_file file # This is pretty slow
    @white_canvas_geometry = Geometry.from_file @white_canvas
  end

  def make
    dst = Tempfile.new([@basename, @format].compact.join("."))
    dst.binmode

    begin
      # PAWIEN: change original "stringy" approach to arrayish approach
      # inspired by the thumbnail processor
      options = [
      	"-gravity",
        "center",
        "#{@white_canvas}",
         #"#{@current_geometry.width.to_i}x#{@current_geometry.height.to_i}+#{@watermark_geometry.height.to_i / 2}+#{@watermark_geometry.width.to_i / 2}",
        File.expand_path(@file.path),
        File.expand_path(dst.path)
      ].flatten.compact.join(" ").strip.squeeze(" ")

      success = Paperclip.run("composite", options)
    rescue PaperclipCommandLineError
      raise PaperclipError, "There was an error processing the watermark for #{@basename}"
    end
    dst
  end

  end
end