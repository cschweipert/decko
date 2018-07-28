# -*- encoding : utf-8 -*-

module Decko
  # For use in REST API specs
  module RestSpecMethods
    def with_token_for usermark
      yield Card[usermark].account.reset_token
    end
  end

  module RestSpecHelper
    def self.describe_api &block
      RSpec.describe CardController, type: :controller do
        routes { Decko::Engine.routes }
        include Capybara::DSL
        include RestSpecMethods
        instance_eval(&block)
      end
    end
  end
end
