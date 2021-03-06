module Kubes
  class Kubectl
    extend Memoist
    include Kubes::Util::Sh

    def initialize(name, options={})
      @name, @options = name, options
    end

    def run
      validate!

      options = @options.dup
      options[:exit_on_fail] = exit_on_fail unless exit_on_fail.nil?

      params = args.flatten.join(' ')
      command = "kubectl #{@name} #{params}" # @name: apply or delete

      switch_context do
        run_hooks(@name) do
          if options[:capture]
            capture(command, options)
          else
            sh(command, options)
          end
        end
      end
    end

    def execute(args, options={})
      command = "kubectl #{args}"
      capture(command)
    end

    # Useful for kustomize mode
    def validate!
      return true unless Kubes.kustomize?

      unless @options[:role]
        logger.error "Missing argument: A folder must be provided when using kustomization.yaml files".color(:red)
        logger.info "Please provide a folder"
        exit 1
      end
    end

    def exit_on_fail
      kubectl = Kubes.config.kubectl
      exit_on_fail = kubectl.send("exit_on_fail_for_#{@name}")
      exit_on_fail.nil? ? kubectl.exit_on_fail : exit_on_fail
    end

    def switch_context(&block)
      kubectl = Kubes.config.kubectl
      context = kubectl.context
      if context
        previous_context = capture("kubectl config current-context")
        sh("kubectl config use-context #{context}", mute: true)
        result = block.call
        if !previous_context.blank? && !kubectl.context_keep
          sh("kubectl config use-context #{previous_context}", mute: true)
        end
        result
      else
        block.call
      end
    end

    def run_hooks(name, &block)
      hooks = Kubes::Hooks::Builder.new(name, "#{Kubes.root}/.kubes/config/kubectl/hooks.rb")
      hooks.build # build hooks
      hooks.run_hooks(&block)
    end

    def args
      # base at end in case of redirection. IE: command > /path
      custom.args + default.args
    end

    def custom
      custom = Kubes::Args::Custom.new(@name, "#{Kubes.root}/.kubes/config/kubectl/args.rb")
      custom.build
      custom
    end
    memoize :custom

    def default
      klass = Kubes.kustomize? ? Args::Kustomize : Args::Standard
      klass.new(@name, @options)
    end
    memoize :default

    class << self
      def run(name, options={})
        new(name, options).run
      end
    end
  end
end

