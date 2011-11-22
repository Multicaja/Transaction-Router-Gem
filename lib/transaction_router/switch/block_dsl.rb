# coding: utf-8
module TransactionRouter
  class Switch
    class BlockDsl

      attr_reader :after_block, :before_block, :simulate_block

      def has_after_block?
        not after_block.nil?
      end

      def has_before_block?
        not before_block.nil?
      end

      def has_simulate_block?
        not simulate_block.nil?
      end

      private
      def before_call(&block)
        raise "El bloque de before_call debe recibir 1 argumento (params)" unless block.arity == 1
        @before_block = block
      end

      def after_call(&block)
        raise "El bloque de after_call debe recibir 2 argumentos (response y params)" unless block.arity == 2
        @after_block = block
      end

      def simulate_call(&block)
        raise "El bloque de simulate_call debe recibir 1 argumento (params)" unless block.arity == 1
        @simulate_block = block
      end

    end
  end
end
