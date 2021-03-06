require "render_me_pretty"

class Kubes::Compiler::Strategy
  class Erb < Base
    extend Kubes::Compiler::Dsl::Core::Fields
    include Kubes::Compiler::Dsl::Core::Helpers
    include Kubes::Compiler::Shared::Helpers
    include Kubes::Compiler::Layering

    def run
      @data = {}

      render_files(pre_layers)
      render(@path) # main resource definition
      render_files(post_layers)

      Result.new(@save_file, @data)
    end

    def render_files(paths)
      paths.each do |path|
        render(path)
      end
    end

    # render and merge
    def render(path)
      result = render_result(path)
      @data.deeper_merge!(result)
    end

    def render_result(path)
      if File.exist?(path)
        yaml = RenderMePretty.result(path, context: self)
        result = YAML.load(yaml)
        result.is_a?(Hash) ? result : {} # in case of blank yaml doc a Boolean false is returned
      else
        {}
      end
    end
  end
end
