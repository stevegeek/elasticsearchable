# frozen_string_literal: true

module Elasticsearchable
  class Query
    def initialize(query_string, **options)
      @options = options
      @query_string = query_string
      @page = options[:page]&.to_i || options[:current_page]&.to_i || 1
      @page_size = options[:page_size]&.to_i || 20
      @indexed_with_composite_id = options[:indexed_with_composite_id]
    end

    attr_reader :query_string, :page, :page_size, :options, :indexed_with_composite_id

    def query
      raise NotImplementedError
    end

    def model_klass
      raise NotImplementedError
    end

    def from
      page_size * ((page || 1) - 1)
    end

    def search
      model_klass.search(
        query,
        from: from,
        size: page_size
      )
    end

    def memoized_search
      @memoized_search ||= search.tap do |es|
        Rails.logger.info("Elasticsearch took #{es.took} ms", caller: self.class.name, action: :search)
      end
    end

    delegate :results, to: :memoized_search

    delegate :records, to: :memoized_search

    def scores
      results.map(&:_score)
    end

    def normalised_scores
      s = scores
      n = s.max
      s.map { |v| v / n }
    end

    def relation
      return model_klass.where(model_klass.primary_key => record_ids) if indexed_with_composite_id?
      records.records
    end

    # https://stackoverflow.com/questions/29096269
    def ordered_relation
      relation.order(Arel.sql("position(id::text in '#{record_ids.join(",")}')"))
    end

    def score_map
      memoized_search.results.map { |d| [d._source["id"], d._score] }.to_h
    end

    def record_ids
      memoized_search.results.map { |d| d._source["id"] }
    end

    def indexed_with_composite_id?
      indexed_with_composite_id || model_klass.indexed_with_composite_id?
    end

    def total_count
      memoized_search.results.total
    end
  end
end
