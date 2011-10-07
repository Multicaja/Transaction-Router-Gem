# coding: utf-8

require "transaction_router/switch/file_gateway"
require "transaction_router/switch/class_gateway"
require "transaction_router/switch/ws_gateway"

module TransactionRouter
  class Switch
    module Gateway
      extend ActiveSupport::Concern

      include FileGateway
      include ClassGateway
      include WsGateway

      module ClassMethods

        # los métodos que enrutan la transacción a una clase, archivo o webservice son definidos en los gateways respectivos

        def before_call(transaction_name, params)
          obj = instance_class transaction_name
          if obj.class.method_defined? :before_call
            Switch.log.debug "Switch->[#{transaction_name}]: La clase #{obj.class} contiene before_call. Invocando..."
            obj.before_call params
          end
        end

        # Se llama después de resolver la transacción, con los resultados arrojados por quien la ejecutó
        def after_call(transaction_name, result, params)
          obj = instance_class transaction_name
          if obj.class.method_defined? :after_call
            Switch.log.debug "Switch->[#{transaction_name}]: La clase #{obj.class} contiene after_call. Invocando..."
            obj.after_call result, params
          end
        end

        def log_routing_file transaction_name
          log_routing_starting transaction_name, :file
        end

        def log_routing_class transaction_name
          log_routing_starting transaction_name, :class
        end

        def log_routing_ws transaction_name
          log_routing_starting transaction_name, :ws
        end

        def log_routing_starting transaction_name, type
          Switch.log.debug "Switch->[#{transaction_name}]: Enrutando la transacción por #{type}"
        end

      end # ClassMethods
    end
  end
end
