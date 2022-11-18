# frozen_string_literal: true

module Elasticsearchable
  class IndexUpdaterJob < ApplicationJob # TODO: How to configure the base class?
    cattr_accessor :disabled

    queue_as :default

    def perform(operation, record_klass, record_id, custom_index_id = nil)
      return if disabled
      record = record_klass.safe_constantize.find(record_id)
      index_id = custom_index_id || record.id
      ::Rails.logger.debug "Do #{operation} w. ID: #{record_id}:#{index_id}", caller: self.class.name
      case operation
      when :index
        index(record, index_id)
      when :reindex
        reindex(record, index_id)
      when :update
        update(record, index_id)
      when :delete
        delete(record, index_id)
      else raise ArgumentError, "Unknown operation '#{operation}'"
      end
    end

    private

    def index(record, index_id)
      record.__elasticsearch__.index_document(id: index_id)
    end

    def update(record, index_id)
      record.__elasticsearch__.update_document(id: index_id)
    end

    def delete(record, index_id)
      record.__elasticsearch__.delete_document(id: index_id)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      ::Rails.logger.debug "Article not found, ID: #{index_id}"
    end

    def reindex(record, index_id)
      begin
        record.__elasticsearch__.delete_document(id: index_id)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        # ignore
      end
      record.__elasticsearch__.index_document(id: index_id)
    end
  end
end
