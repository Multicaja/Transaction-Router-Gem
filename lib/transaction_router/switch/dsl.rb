# coding: utf-8

module TransactionRouter
  class Switch
    class Dsl

      attr_reader :route_set

      def initialize(routes = {})
        @route_set = routes
        @valid_types = [:file, :klass, :ws, :inline]
        @valid_options = { 
          :klass =>   [ :klass, :min_args ],
          :file =>    [ :filename, :filepath, :on_file_not_found_exception, :klass, :min_args ],
          :ws =>      [ :klass, :uri, :namespace, :open_timeout, :read_timeout, :on_timeout_exception, 
                        :on_http_error_exception, :on_soap_error_exception, :on_empty_response_exception, 
                        :logger, :min_args ],
          :inline =>  [ :min_args ]
        }
      end

      private
      def file(trx_name, options = {}, &block)
        route :file, trx_name, options, &block
      end

      def klass(trx_name, options = {}, &block)
        route :klass, trx_name, options, &block
      end

      def ws(trx_name, options = {}, &block)
        route :ws, trx_name, options, &block
      end

      def inline(trx_name, options = {}, &block)
        raise "Las transacciones inline requieren un bloque" if block.nil?
        route :inline, trx_name, options, &block
      end

      def route(route_type, trx_name, options = {}, &block)
        raise "La ruta de la transacción #{trx_name} tiene un error: el tipo #{route_type} es inválido" unless @valid_types.include? route_type
        validate_options route_type, trx_name, options
        bd = BlockDsl.new
        if block
          bd.instance_exec &block
          validate_block block
        end
        @route_set[trx_name] = { :type => route_type, :options => options, :blocks => bd }
      end

      def validate_options(route_type, trx_name, options)
        options.each do |opn, opv|
          unless @valid_options[route_type].include? opn
            raise "La ruta de la transacción #{trx_name} tiene un error: la opción #{opn.to_s} es inválida en #{route_type}"
          end
        end
      end

      def validate_block(block)
        raise "El bloque no debe recibir argumentos" if block.arity > 0
      end

    end
  end
end
