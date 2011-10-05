module TransactionRouter
  class Switch
    
    class_attribute :route_set
    class_attribute :settings

    class << self

      def init(settings = {})
        default_settings = {}
        default_settings[:relative_file_path] = "test"
        default_settings[:root_path] = Rails.root.to_s
        # Se arroja cuando una transacción es ejecutada con su método bang y el gateway no retorna 01
        default_settings[:bang_method_exception] = Application::ValidationError
        # Se arroja cuando una transacción debe retornar archivo, pero éste no existe
        default_settings[:on_file_not_found_exception] = Application::BaseWsError
        # Se arroja cuando una transación no puede encontrar su clase respectiva
        default_settings[:on_class_not_found_exception] = Application::ValidationError
        self.settings = default_settings.merge settings
      end

      def trx_options(name)
        raise "La ruta no existe" unless self.route_set[name]
        self.route_set[name][:options]
      end

    end # ClassMethods

  end
end
