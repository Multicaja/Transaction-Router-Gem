# coding: utf-8
module TransactionRouter
  class Switch
    module ClassGateway
      extend ActiveSupport::Concern

      module ClassMethods

        # Responde la transacción con un método
        def simulado(transaction_name, params)
          klass = class_name transaction_name
          if class_exists? klass
            klass = const_get klass
            simulator = klass.new
            response = simulator.simulate params
          else
            raise Application::ValidationError, "La transacción #{transaction_name} no se pudo simular porque no existe la clase #{klass}" 
          end
          response
        end

        def class_name(transaction_name)
          op = trx_options transaction_name
          klass = op[:class] || "#{transaction_name.camelize}Transaction"
        end

        def class_exists?(class_name)
          begin
            klass = Module.const_get(class_name)
            return klass.is_a?(Class)
          rescue NameError
            return false
          end
        end
        
      end # ClassMethods
    end
  end
end

