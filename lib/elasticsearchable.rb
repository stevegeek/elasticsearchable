# frozen_string_literal: true

require_relative "elasticsearchable/version"

module Elasticsearchable
  class << self
    attr_reader :configuration

    def configure
      @configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end
  end

  # Configuration class for initializer
  class Configuration
    # @dynamic devise_password_hash
    attr_accessor :index_name_prefix, :index_name_includes_environment

    def initialize
      @index_name_prefix = ""
      @index_name_includes_environment = true
    end
  end
end
