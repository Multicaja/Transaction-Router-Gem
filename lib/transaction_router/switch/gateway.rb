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
          validate_min_args transaction_name, params
          if blocks(transaction_name).has_before_block?
            blocks(transaction_name).before_block.call params
          end
          obj = instance_class transaction_name
          if obj.class.method_defined? :before_call
            Switch.log.debug "Switch->[#{transaction_name}]: La clase #{obj.class} contiene before_call. Invocando..."
            obj.before_call params
          end
        end

        # Se llama después de resolver la transacción, con los resultados arrojados por quien la ejecutó
        def after_call(transaction_name, result, params)
          if blocks(transaction_name).has_after_block?
            blocks(transaction_name).after_block.call result, params
          end
          obj = instance_class transaction_name
          if obj.class.method_defined? :after_call
            Switch.log.debug "Switch->[#{transaction_name}]: La clase #{obj.class} contiene after_call. Invocando..."
            obj.after_call result, params
          end
          translate_result result
        end

        # Se llama para simular la respuesta si la transacción es de tipo inline
        def inline(transaction_name, params)
          if blocks(transaction_name).has_simulate_block?
            blocks(transaction_name).simulate_block.call params
          else
            raise "La transacción #{transaction_name} es de tipo inline pero no definió ningún simulate_call"
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

        private
        def validate_min_args(transaction_name, params)
          ma = Switch.trx_options(transaction_name)[:min_args]
          if ma and ma.kind_of? Array
            ma.each do |arg|
              raise Switch.settings[:missing_arg_exception], "La transacción #{transaction_name} requiere el parámetro #{arg}" unless params.include? arg
            end
          end
        end

        def translate_result(result)
          translated = {}
          result.each do |k,v|
            if k.is_a? String
              translated[k.downcase.to_sym] = v
            end
          end
          translated.each do |k,v|
            result[k] = v unless result[k]
          end
          if Switch.settings[:force_result_translation]
            result.delete_if{|k,v| k.is_a?(String)}
          end
        end

        def blocks(transaction_name)
          Switch.trx_blocks(transaction_name)
        end

      end # ClassMethods
    end
  end
end
