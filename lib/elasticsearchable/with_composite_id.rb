# frozen_string_literal: true

module Elasticsearchable
  module WithCompositeId
    extend ActiveSupport::Concern

    included do
      after_commit on: [:create, :update] do
        ::Elasticsearchable::IndexUpdaterJob.perform_later(
          :reindex,
          self.class.name,
          id,
          elasticsearch_composite_id
        )
      end

      after_commit on: [:destroy] do
        ::Elasticsearchable::IndexUpdaterJob.perform_later(
          :delete,
          self.class.name,
          id,
          elasticsearch_composite_id
        )
      end
    end

    class_methods do
      def indexed_with_composite_id?
        true
      end
    end

    def elasticsearch_composite_id
      raise NotImplementedError
    end
  end
end
