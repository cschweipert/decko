require "cardio"
require "decko"

module Decko
  class Engine < ::Rails::Engine
    paths.add "config/routes.rb", with: "config/engine_routes.rb"
    paths.add "lib/tasks", with: "#{::Decko.gem_root}/lib/decko/tasks",
                           glob: "**/*.rake"
    paths["lib/tasks"] << "#{Cardio.gem_root}/lib/card/tasks"
    paths.add "decko/config/initializers",
              with: File.join(Decko.gem_root, "config/initializers"),
              glob: "**/*.rb"

    initializer "decko.engine.load_config_initializers",
                after: :load_config_initializers do
      paths["decko/config/initializers"].existent.sort.each do |initializer|
        load(initializer)
      end
    end

    initializer "engine.copy_configs",
                before: "decko.engine.load_config_initializers" do
      Engine.paths["lib/tasks"] = Decko.paths["lib/tasks"]
      Engine.paths["config/routes.rb"] = Decko.paths["config/routes.rb"]
    end

    initializer :connect_on_load do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.establish_connection(::Rails.env.to_sym)
      end
    end
  end
end
