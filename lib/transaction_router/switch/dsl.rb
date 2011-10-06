# coding: utf-8
module TransactionRouter
  class Switch
    class Dsl

      attr_reader :route_set

      def initialize(routes = {})
        @route_set = routes
        @valid_types = [:file, :klass, :ws]
        @valid_options = { 
          :klass => [:class], 
          :file => [:filename, :filepath, :on_file_not_found_exception],
          :ws => [] 
        }
      end

      private
      def file(trx_name, options = {})
        route :file, trx_name, options
      end

      def klass(trx_name, options = {})
        route :klass, trx_name, options
      end

      def ws(trx_name, options = {})
        route :ws, trx_name, options
      end

      def route(route_type, trx_name, options = {})
        raise "La ruta de la transacción #{trx_name} tiene un error: el tipo #{route_type} es inválido" unless @valid_types.include? route_type
        validate_options route_type, trx_name, options
        @route_set[trx_name] = { :type => route_type, :options => options }
      end

      def validate_options(route_type, trx_name, options)
        options.each do |opn, opv|
          unless @valid_options[route_type].include? opn
            raise "La ruta de la transacción #{trx_name} tiene un error: la opción #{opn.to_s} es inválida en #{route_type}"
          end
        end
      end

    end
  end
end
