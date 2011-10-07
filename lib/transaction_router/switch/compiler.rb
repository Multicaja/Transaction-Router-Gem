# coding: utf-8

require "transaction_router/switch/dsl"

module TransactionRouter
  class Switch
    module Compiler
      extend ActiveSupport::Concern

      module ClassMethods

        # Es el método que se ejecuta cuando se inicializa el Switch de transacciones. 
        # Este método crea en el Switch todos los métodos mencionados por el DSL
        def draw(&block)
          dsl = Dsl.new
          if block.arity >= 1
            raise "El DSL de transacciones debe ser escrito en un bloque que no recibe parámetros"
          end
          dsl.instance_exec &block
          Switch.route_set = dsl.route_set
          compile
        end

        # Se llama para sobreescribir el comportamiento de una ruta específica
        def override_route(name, type, options = {})
          # Si la clase ya está instanciada, habrá que instanciarla de nuevo
          class_cache.delete name if class_cache.key? name
          # Hay que sobreescribir las opciones de la ruta
          Switch.route_set[name] = { :type => type, :options => options }
          # Finalmente, hay que escribir el nuevo método
          case type
          when :file
            answer_with_file name, settings
          when :klass
            answer_with_class name, settings
          else # :ws
            answer_with_ws name, settings
          end
        end

        private

        def answer_with_file(name, settings)
          class_eval <<-METODO_ARCHIVO, __FILE__, __LINE__ + 1
            def self.#{name}(params)
              log_routing_file "#{name}"
              before_call :#{name}, params
              result = file(:#{name}, params)
              after_call :#{name}, result, params
              result
            end
          METODO_ARCHIVO
        end

        def answer_with_class(name, settings)
          class_eval <<-METODO_SIMULADO, __FILE__, __LINE__ + 1
            def self.#{name}(params)
              log_routing_class "#{name}"
              before_call :#{name}, params
              result = code(:#{name}, params)
              after_call :#{name}, result, params
              result
            end
          METODO_SIMULADO
        end

        def answer_with_ws(name, settings)
          class_eval <<-METODO_WS, __FILE__, __LINE__ + 1
            def self.#{name}(params)
              log_routing_ws "#{name}"
              before_call :#{name}, params
              result = ws(:#{name}, params)
              after_call :#{name}, result, params
              result
            end
          METODO_WS
        end

        def compile
          puts "Conjunto de rutas: #{Switch.route_set}"
          Switch.route_set.each do |name, settings|
            case settings[:type]
            when :file
              answer_with_file name, settings
            when :klass
              answer_with_class name, settings
            else # :ws
              answer_with_ws name, settings
            end
            class_eval <<-METODO_BANG, __FILE__, __LINE__ + 1
              def self.#{name}!(params)
                result = #{name}(params)
                raise(#{Switch.settings[:bang_method_exception]}, "La transacción no arrojó 01:'" + result["MENSAJE_RESPUESTA"] + "'") if result["CODIGO_RESPUESTA"] != "01"
                result
              end
            METODO_BANG
            end # foreach route
        end # compile method
      end # ClassMethods

    end # RouteBuilder 
  end
end
