# coding: utf-8

require "transaction_router/switch/webservice_client"

module TransactionRouter
  class Switch
    module WsGateway
      extend ActiveSupport::Concern

      module ClassMethods

        # Responde la transacción con el webservice
        def ws(transaction_name, payload)
          Switch.log.debug "Switch->[#{transaction_name}]: Se invocará el ws..."
          ws_payload = {}
          # El hash viene con símbolos como llaves, las que tienen que pasar a strings en mayúsculas
          payload.map{ |k,v| ws_payload[k.to_s.upcase] = v }
          response = WebserviceClient.call(transaction_name.to_s.upcase, ws_payload, Switch.trx_options(transaction_name))
          response
        end

      end # ClassMethods
    end
  end
end

