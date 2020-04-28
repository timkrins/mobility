# frozen-string-literal: true
require "mobility/arel"

module Mobility
  module Arel
    module Nodes
      %w[
        HstoreDashArrow
        HstoreQuestion
      ].each do |name|
        const_set name, (Class.new(Binary) do
          include ::Arel::Predications
          include ::Arel::OrderPredications
          include ::Arel::AliasPredication
          include ::Mobility::Arel::MobilityExpressions

          def lower
            super self
          end
        end)
      end

      # Needed for AR 4.2, can be removed when support is deprecated
      if ::ActiveRecord::VERSION::STRING < '5.0'
        HstoreDashArrow.class_eval do
          def quoted_node other
            other && super
          end
        end
      end

      class Hstore < HstoreDashArrow
        def to_question
          HstoreQuestion.new left, right
        end

        def eq other
          other.nil? ? to_question.not : super
        end
      end
    end

    module Visitors
      def visit_Mobility_Arel_Nodes_HstoreDashArrow o, a
        json_infix o, a, '->'
      end

      def visit_Mobility_Arel_Nodes_HstoreQuestion o, a
        json_infix o, a, '?'
      end

      private

      def json_infix o, a, opr
        visit(Nodes::Grouping.new(::Arel::Nodes::InfixOperation.new(opr, o.left, o.right)), a)
      end
    end

    ::Arel::Visitors::PostgreSQL.include Visitors
  end
end
