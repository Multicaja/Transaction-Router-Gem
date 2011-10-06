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
          obj = load_class transaction_name
          if obj.class.method_defined? :before_call
            obj.before_call params
          end
        end

        # Se llama después de resolver la transacción, con los resultados arrojados por quien la ejecutó
        def after_call(transaction_name, result, params)
          obj = load_class transaction_name
          if obj.class.method_defined? :after_call
            obj.after_call result, params
          end
        end

      end # ClassMethods
    end
  end
end
