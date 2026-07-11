##
# Module concern with methods to help find records with tags
#
module Taggable
  extend ActiveSupport::Concern

  def self.models
    @models ||= []
  end

  included do
    Taggable.models << self

    has_tag_string

    def self.with_tag(tag)
      where(tag_search_relation(tag).arel.exists)
    end

    def self.without_tag(tag)
      where.not(tag_search_relation(tag).arel.exists)
    end

    def self.tag_search_relation(tag)
      name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(tag)
      tag_table = HasTagString::HasTagStringTag.arel_table
      model_table = arel_table
      predicate = tag_table[:model_id].eq(model_table[primary_key]).
        and(tag_table[:model_type].eq(to_s)).
        and(tag_table[:name].eq(name))
      predicate = predicate.and(tag_table[:value].eq(value)) if value
      HasTagString::HasTagStringTag.where(predicate).select(1)
    end
    private_class_method :tag_search_relation

    def self.tags
      HasTagString::HasTagStringTag.where(model_id: all, model_type: to_s).
        map(&:name_and_value)
    end
  end
end
