require "base64"

module Kubes::Compiler::Shared
  module Helpers
    extend Kubes::Compiler::Dsl::Core::Fields
    fields "name"

    def built_image
      return @options[:image] if @options[:image] # override

      path = Kubes.config.state.docker_image_path
      unless File.exist?(path)
        raise "Missing file with docker image built by kubes: #{path}. Try first running: kubes docker build"
      end
      IO.read(path)
    end

    def with_extra(value)
      [value, extra].compact.join('-')
    end

    def extra
      extra = ENV['KUBES_EXTRA']
      extra&.strip&.empty? ? nil : extra # if blank string then also return nil
    end

    def base64(v)
      Base64.encode64(v).strip
    end
  end
end
