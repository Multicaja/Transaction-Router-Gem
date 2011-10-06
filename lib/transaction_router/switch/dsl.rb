# coding: utf-8
module TransactionRouter
  class Switch
    class Dsl

      def initialize(route_set = [])
        @route_set = route_set
        @valid_types = [:file, :class, :ws]
        @valid_options = { 
          :klass => [:class], 
          :file => [:filename, :filepath], 
          :ws => [] 
        }
        @raise_on_duplicates = true
      end

      def route_set
        routes = {}
        @route_set.each do |route|
          if @raise_on_duplicates and routes.key? route[:name]
            raise "La transacción #{route[:name]} ya fue mencionada"
          end
          routes[route[:name]] = { :type => route[:type], :options => route[:options] }
        end
        routes
      end

      private
      def file(trx_name, options = {})
        route :file, trx_name, options
      end

      def class(trx_name, options = {})
        route :class, trx_name, options
      end

      def ws(trx_name, options = {})
        route :ws, trx_name, options
      end

      def route(route_type, trx_name, options = {})
        raise "La ruta de la transacción #{trx_name} tiene un error: el tipo #{route_type} es inválido" unless @valid_types.include? route_type
        validate_options trx_name, options
        @route_set << { :type => route_type, :name => trx_name, :options => options }
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
