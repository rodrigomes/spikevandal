module Paperclip
  # Handles images that are uploaded.
  class Abc < Processor

    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options,
                  :source_file_options, :animated, :auto_orient

    # Creates a Thumbnail object set to work on the +file+ given. It
    # will attempt to transform the image into one defined by +target_geometry+
    # which is a "WxH"-style string. +format+ will be inferred from the +file+
    # unless specified. Thumbnail creation will raise no errors unless
    # +whiny+ is true (which it is, by default. If +convert_options+ is
    # set, the options will be appended to the convert command upon image conversion
    #
    # Options include:
    #
    #   +geometry+ - the desired width and height of the thumbnail (required)
    #   +file_geometry_parser+ - an object with a method named +from_file+ that takes an image file and produces its geometry and a +transformation_to+. Defaults to Paperclip::Geometry
    #   +string_geometry_parser+ - an object with a method named +parse+ that takes a string and produces an object with +width+, +height+, and +to_s+ accessors. Defaults to Paperclip::Geometry
    #   +source_file_options+ - flags passed to the +convert+ command that influence how the source file is read
    #   +convert_options+ - flags passed to the +convert+ command that influence how the image is processed
    #   +whiny+ - whether to raise an error when processing fails. Defaults to true
    #   +format+ - the desired filename extension
    def initialize(file, options = {}, attachment = nil)
      super

      geometry             = options[:geometry] # this is not an option
      @file                = file
      @target_geometry     = (options[:string_geometry_parser] || Geometry).parse(geometry)
      @current_geometry    = (options[:file_geometry_parser] || Geometry).from_file(@file)
      @source_file_options = options[:source_file_options]
      @convert_options     = options[:convert_options]
      @whiny               = options[:whiny].nil? ? true : options[:whiny]
      @format              = options[:format]
      @auto_orient         = options[:auto_orient].nil? ? true : options[:auto_orient]
      if @auto_orient && @current_geometry.respond_to?(:auto_orient)
        @current_geometry.auto_orient
      end

      @source_file_options = @source_file_options.split(/\s+/) if @source_file_options.respond_to?(:split)
      @convert_options     = @convert_options.split(/\s+/)     if @convert_options.respond_to?(:split)

      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
    end

    # Performs the conversion of the +file+ into a thumbnail. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      dst = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
      dst.binmode

      begin
        parameters = []
        parameters << source_file_options
        parameters << ":source"
        ##parameters << transformation_command
        parameters << convert_options
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        success = convert(parameters, :source => "#{File.expand_path(src.path)}#{'[0]'}", :dest => File.expand_path(dst.path))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error processing the thumbnail for #{@basename}" if @whiny
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      dst
    end

    # Returns the command ImageMagick's +convert+ needs to transform the image
    # into the thumbnail.
    def transformation_command
      scale = @current_geometry.transformation_to(@target_geometry)
      trans = []
      trans << "-auto-orient" if auto_orient
      trans << "-resize" << %["#{scale}"] unless scale.nil? || scale.empty?
      trans
    end

  end
end