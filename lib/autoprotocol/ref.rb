module Autoprotocol
  # Link a ref name (string) to a Container instance
  class Ref
    attr_accessor :name, :opts, :container
    def initialize(name, opts, container)
      self.name = name
      self.opts = opts
      self.container = container
    end
  end
end
