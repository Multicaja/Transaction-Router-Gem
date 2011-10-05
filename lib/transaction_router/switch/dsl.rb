# coding: utf-8
module TransactionRouter
  class Switch
    class Dsl

      def initialize()
        @route_set = []
        @valid_types = [:file, :class, :ws]
        @valid_options = [:class]
        @raise_on_duplicates = true
      end

      def route_set
        routes = {}
        @route_set.map do |route|
          if @raise_on_duplicates and routes.key? route[:type]
            raise "La transacción #{route[:type]} ya fue mencionada"
          end
          routes[route[:name]] = { :type => route[:type], :options => route[:options] }
        end
        routes
      end

      private
      def file(trx_name, options)
        route :file, trx_name, options
      end

      def class(trx_name, options)
        route :class, trx_name, options
      end

      def ws(trx_name, options)
        route :ws, trx_name, options
      end

      def route(route_type, trx_name, options = {})
        raise "La ruta de la transacción #{trx_name} tiene un error: el tipo #{route_type} es inválido" unless @valid_types.include? route_type
        validate_options trx_name, options
        @route_set << { :type => route_type, :name => trx_name, :options => options }
      end

      def validate_options(trx_name, options)
        options.each do |opn, opv|
          raise "La ruta de la transacción #{trx_name} contiene una opción inválida: #{opn.to_s}" unless @valid_options.include? opn
        end
      end

    end
  end
end
