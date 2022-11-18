# frozen_string_literal: true

module Elasticsearchable
  module Searchable
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Model

      # TODO: config values
      index_name index_name_for_model

      class << self
        # Original import method
        alias_method :lib_import, :import
      end
    end

    class_methods do
      def indexed_with_composite_id?
        false
      end

      def clear_index!
        __elasticsearch__.create_index! force: true
      end

      def index_name_for_model
        [
          Elasticsearchable.configuration.index_name_prefix,
          Elasticsearchable.configuration.index_name_includes_environment ? Rails.env : nil,
          model_name.collection
        ].compact_blank.join("_")
      end
    end

    # Default representation is JSON serialised version
    def as_indexed_json(options = {})
      as_json(options.merge(root: false))
    end
  end
end
