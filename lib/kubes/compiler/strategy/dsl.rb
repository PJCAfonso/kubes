class Kubes::Compiler::Strategy
  class Dsl < Base
    def run
      klass = syntax_class
      syntax = klass.new(@options) # Deployment, Service, etc
      data = syntax.run
      Result.new(@save_file, data)
    end

    def syntax_class
      # Remove .kubes/resources
      klass_name = File.basename(@filename).sub('.rb','').underscore.camelize # Deployment, Service, Ingress, ManagedCertificate, etc
      klass_name = klass_map(klass_name)
      "Kubes::Compiler::Dsl::Syntax::#{klass_name}".constantize
    rescue NameError => e
      logger.debug "#{e.class}: #{e.message}"
      logger.warn "WARN: Using default resource: #{klass_name}".color(:red)
      Kubes::Compiler::Dsl::Syntax::Resource # default
    end

    # Allows user to name the files:
    #
    #   managedcertificate => managed_certificate
    #
    def klass_map(klass_name)
      map = {
        Backendconfig: "BackendConfig",
        Managedcertificate: "ManagedCertificate",
      }
      map[klass_name.to_sym] || klass_name
    end
  end
end
