# coding: utf-8
module TransactionRouter
  class Switch
    module ClassLoader
      extend ActiveSupport::Concern

      module ClassMethods

        # Retorna la clase asociada a la transacción
        def load_class(transaction_name)
          unless self.class_cache.key? transaction_name
            # La clase no ha sido cargada, la cargamos y guardamos en el caché
            klass = class_name transaction_name
            Switch.log.debug "Switch->[#{transaction_name}]: La clase #{klass} no se encuentra en el caché. Instanciando..."
            if class_exists? klass
              klass = const_get klass
              simulator = klass.new
              self.class_cache[transaction_name] = simulator
            else
              Switch.log.error "Switch->[#{transaction_name}]: Ups! No se encontró la clase #{klass}..."
              raise self.settings[:on_class_not_found_exception], "La transacción #{transaction_name} no se pudo simular porque no existe la clase #{klass}" 
            end
          end
          # La clase ya está cargada, la retornamos del caché
          self.class_cache[transaction_name]
        end

        def class_name(transaction_name)
          op = trx_options transaction_name
          klass = op[:class] || "#{transaction_name.to_s.camelize}Transaction"
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

