module Kubes::Kubectl::Fetch
  class Deployment < Base
    extend Memoist

    def metadata
      deployment['metadata']
    end

    def spec
      deployment['spec']
    end

    def deployment
      items = fetch_items
      # Not checking if deployment exists because kubes will error on `kubes get` from missing deployments already
      deployments = items.select { |i| i['kind'] == "Deployment" }

      if deployments.size > 1 && !@options[:name]
        names = deployments.map { |d| d['metadata']['name'] }
        logger.info <<~EOL
          INFO: More than one deployment found.
          Deployment names: #{names.join(', ')}
          Using #{names.first}
          Note: You can specify the deployment to use with --name or -n
        EOL
      end

      deployment = find_deployment(deployments)
      unless deployment
        logger.error "ERROR: No deployment found".color(:red)
        exit 1
      end
      deployment
    end
    memoize :deployment

    def find_deployment(deployments)
      if @options[:name]
        deployments.find { |d| d['metadata']['name'] == @options[:name] }
      else
        deployments.first
      end
    end
  end
end
