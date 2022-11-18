# frozen_string_literal: true

module Elasticsearchable
  module Updates
    extend ActiveSupport::Concern

    included do
      after_commit on: [:create] do
        ::Elasticsearchable::IndexUpdaterJob.perform_later(:index, self.class.name, id)
      end

      after_commit on: [:update] do
        ::Elasticsearchable::IndexUpdaterJob.perform_later(:update, self.class.name, id)
      end

      after_commit on: [:destroy] do
        ::Elasticsearchable::IndexUpdaterJob.perform_later(:delete, self.class.name, id)
      end
    end
  end
end
