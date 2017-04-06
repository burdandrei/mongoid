# encoding: utf-8
module Mongoid
  module Associations
    module Referenced
      class HasMany

        # Builder class for has_many associations.
        class Builder
          include Buildable

          # This builder either takes a hash and queries for the
          # object or an array of documents, where it will just return tem.
          #
          # @example Build the documents.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Array<Document> ] The documents.
          def build(type = nil)
            return object unless query?
            return [] if object.is_a?(Array)
            association.criteria(association.flag(object), base.class)
          end
        end
      end
    end
  end
end

