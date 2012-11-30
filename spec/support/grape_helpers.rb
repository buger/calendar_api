require "spec_helper"

module RSpec
  module AuthHelpher
    extend ActiveSupport::Concern

    included do
      [:get, :post, :put, :delete].each do |meth|
        class_exec do
          define_method meth do |path, params = nil|
            super("#{path}?#{api_key}", params)
          end
        end
      end
    end
  end
end

