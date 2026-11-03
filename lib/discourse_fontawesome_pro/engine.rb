# frozen_string_literal: true

module ::DiscourseFontawesomePro
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseFontawesomePro
    config.autoload_paths << File.join(config.root, "lib")
  end
end
