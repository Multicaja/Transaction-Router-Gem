module TransactionRouter
  class Switch
    class Dsl

      def initialize()
        @route_set = []
        @valid_types = [:file, :class, :ws]
        @raise_on_duplicates = true
      end

      def route_set
        routes = {}
        @route_set.map do |route|
          if @raise_on_duplicates and routes.key? route[:type]
            raise "La transacción #{route[:type]} ya fue mencionada"
          end
          routes[route[:name]] = route[:type]
        end
        routes
      end

      private
      def file(trx_name)
        route :file, trx_name
      end

      def class(trx_name)
        route :class, trx_name
      end

      def ws(trx_name)
        route :ws, trx_name
      end

      def route(route_type, trx_name)
        raise "La ruta de la transacción #{trx_name} tiene un error: el tipo #{route_type} es inválido", unless @valid_types.include? route_type
        @route_set << { :type => route_type, :name => trx_name }
      end
    end
  end
end
