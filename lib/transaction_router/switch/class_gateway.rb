# coding: utf-8
module TransactionRouter
  class Switch
    module ClassGateway
      extend ActiveSupport::Concern

      module ClassMethods

        # Responde la transacción con un método
        def code(transaction_name, params)
          # Switch.log.debug "Switch->[#{transaction_name}]: Se ejecutará una clase..."
          # Se arrojará una excepción si no se encuentra la clase
          klass = instance_class! transaction_name
          klass.simulate params
        end

      end # ClassMethods
    end
  end
end

