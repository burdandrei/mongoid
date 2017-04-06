# encoding: utf-8
module Mongoid
  module Associations

    # Superclass for all objects that bind relations together.
    module Bindable
      include Threaded::Lifecycle

      attr_reader :base, :target, :association

      # Create the new binding.
      #
      # @example Initialize a binding.
      #   Binding.new(base, target, association)
      #
      # @param [ Document ] base The base of the binding.
      # @param [ Document, Array<Document> ] target The target of the binding.
      # @param [ Association ] association The association metadata.
      #
      # @since 2.0.0.rc.1
      def initialize(base, target, association)
        @base, @target, @association = base, target, association
      end

      # Execute the provided block inside a binding.
      #
      # @example Execute the binding block.
      #   binding.binding do
      #     base.foreign_key = 1
      #   end
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 3.0.0
      def binding
        unless _binding?
          _binding do
            yield(self) if block_given?
          end
        end
      end

      private

      # Check if the inverse is properly defined.
      #
      # @api private
      #
      # @example Check the inverse definition.
      #   binding.check_inverse!(doc)
      #
      # @param [ Document ] doc The document getting bound.
      #
      # @raise [ Errors::InverseNotFound ] If no inverse found.
      #
      # @since 3.0.0
      def check_inverse!(doc)
        unless association.bindable?(doc)
          raise Errors::InverseNotFound.new(
              base.class,
              association.name,
              doc.class,
              association.foreign_key
          )
        end
      end

      # Set the id of the related document in the foreign key field on the
      # keyed document.
      #
      # @api private
      #
      # @example Bind the foreign key.
      #   binding.bind_foreign_key(post, person._id)
      #
      # @param [ Document ] keyed The document that stores the foreign key.
      # @param [ Object ] id The id of the bound document.
      #
      # @since 3.0.0
      def bind_foreign_key(keyed, id)
        unless keyed.frozen?
          keyed.you_must(association.foreign_key_setter, id)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when relations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      #
      # @since 3.0.0
      def bind_polymorphic_type(typed, name)
        if association.type
          typed.you_must(association.type_setter, name)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when relations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_inverse_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      #
      # @since 3.0.0
      def bind_polymorphic_inverse_type(typed, name)
        if association.inverse_type
          typed.you_must(association.inverse_type_setter, name)
        end
      end

      # Bind the inverse document to the child document so that the in memory
      # instances are the same.
      #
      # @api private
      #
      # @example Bind the inverse.
      #   binding.bind_inverse(post, person)
      #
      # @param [ Document ] doc The base document.
      # @param [ Document ] inverse The inverse document.
      #
      # @since 3.0.0
      def bind_inverse(doc, inverse)
        if doc.respond_to?(association.inverse_setter)
          doc.you_must(association.inverse_setter, inverse)
        end
      end

      # Bind the provided document with the base from the parent relation.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   binding.bind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to bind.
      #
      # @since 3.0.0
      def bind_from_relational_parent(doc)
        check_inverse!(doc)
        bind_foreign_key(doc, record_id(base))
        bind_polymorphic_type(doc, base.class.name)
        bind_inverse(doc, base)
      end

      def record_id(base)
        base.__send__(association.primary_key)
      end

      # Ensure that the association on the base is correct, for the cases
      # where we have multiple belongs to definitions and were are setting
      # different parents in memory in order.
      #
      # @api private
      #
      # @example Set the base association.
      #   binding.set_base_association
      #
      # @return [ true, false ] If the association changed.
      #
      # @since 2.4.4
      def set_base_association
        inverse_association = association.inverse_association(target)
        if inverse_association != association && !inverse_association.nil?
          base.__association = inverse_association
        end
      end

      # Bind the provided document with the base from the parent relation.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   unbinding.unbind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to unbind.
      #
      # @since 3.0.0
      def unbind_from_relational_parent(doc)
        check_inverse!(doc)
        bind_foreign_key(doc, nil)
        bind_polymorphic_type(doc, nil)
        bind_inverse(doc, nil)
      end
    end
  end
end
