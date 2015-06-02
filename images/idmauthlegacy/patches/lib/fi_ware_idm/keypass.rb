module FiWareIdm
  module Keypass
    mattr_accessor :enable
    @@enable = false

    mattr_accessor :url

    class << self
      def setup
        yield self
      end
    end
  end
end
