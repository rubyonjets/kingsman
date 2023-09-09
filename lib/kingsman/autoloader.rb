require "zeitwerk"

module Kingsman
  class Autoloader
    class Inflector < Zeitwerk::Inflector
      def camelize(basename, _abspath)
        map = { cli: "CLI", version: "VERSION", omniauth: "OmniAuth" }
        map[basename.to_sym] || super
      end
    end

    class << self
      def setup
        loader = Zeitwerk::Loader.new
        loader.inflector = Inflector.new
        lib = File.dirname(__dir__)
        loader.push_dir(lib) # lib
        loader.do_not_eager_load("#{lib}/generators")
        loader.do_not_eager_load("#{lib}/kingsman/models/omniauthable.rb")
        loader.ignore("#{lib}/kingsman/omniauth.rb")
        loader.ignore("#{lib}/kingsman/hooks")
        loader.ignore("#{lib}/kingsman/jets.rb")
        loader.ignore("#{lib}/kingsman/jets")
        loader.ignore("#{lib}/kingsman/modules.rb")
        loader.ignore("#{lib}/kingsman/orm")
        loader.ignore("#{lib}/kingsman/routes.rb")
        loader.setup
      end
    end
  end
end
