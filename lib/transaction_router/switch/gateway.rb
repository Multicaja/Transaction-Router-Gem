# coding: utf-8
module TransactionRouter
  class Switch
    class Gateway
      extend ActiveSupport::Concern

      include FileGateway
      include ClassGateway

      module ClassMethods
        # Responde la transacción con el webservice
        def ws(transaction_name, payload)
          Rails.logger.debug "ItGateway: Invocando WS-#{transaction_name.upcase}: '#{payload}'"
          Rails.logger.debug "Servidor remoto en [#{ws_uri}]"
          ws_payload = {}
          # El hash viene con símbolos como llaves, las que tienen que pasar a strings en mayúsculas
          payload.map{ |k,v| ws_payload[k.to_s.upcase] = v }
          response = WebserviceClient.call(transaction_name.upcase, ws_payload)
          response
        end

        def before_call(transaction_name, params)
          klass = "#{transaction_name.camelize}Transaction"
          if class_exists? klass
            klass = const_get klass
            obj = klass.new
            if klass.method_defined? :before_call
              obj.before_call params
            end
          end
        end

        # Se llama después de resolver la transacción, con los resultados arrojados por quien la ejecutó
        def after_call(transaction_name, result, params)
          klass = "#{transaction_name.camelize}Transaction"
          if class_exists? klass
            klass = const_get klass
            obj = klass.new
            if klass.method_defined? :after_call
              obj.after_call result, params
            end
          end
        end

        # Retorna +:archivo+, +:simulada, o +:ws+ según la configuración de la transacción
        def route(transaction_name, silent = false)
          trx_name_dc = transaction_name.downcase
          if trx_list.key? trx_name_dc
            str_route = trx_list[trx_name_dc]
          else
            str_route = :no_mencionada_en_config
          end
          str_route_to_symbol str_route
        end

      end

