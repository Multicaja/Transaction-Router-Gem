# coding: utf-8
module TransactionRouter
  class Switch
    class WebserviceClient

      class_attribute :settings

      class << self

        def init(settings = {})
          default_settings = {}
          default_settings[:uri] = APP_CONFIG["ws"]["uri"]
          default_settings[:open_timeout] = APP_CONFIG["ws"]["open_timeout"]
          default_settings[:read_timeout] = APP_CONFIG["ws"]["read_timeout"]
          default_settings[:on_timeout_exception] = Application::BaseWsError
          default_settings[:on_http_error_exception] = Application::BaseWsError
          default_settings[:on_soap_error_exception] = Application::BaseWsError
          default_settings[:on_empty_response_exception] = Application::BaseWsError
          default_settings[:logger] = Rails.logger
          self.settings = default_settings.merge settings
        end

        def log
          self.settings[:logger]
        end

        def call(tipo_tx, params)
          #Item array creation
          item_array = []
    
          params.each do |name, value| 
            item_array << { :nombrecampo => name, :valorcampo => value }
          end
          
          #If the params array doesn't contain the name of the transaction, add it as an item. 
          #TODO: Remove this once all calls to this method are performed through gateway classes.
          unless params.has_key? "TIPO_TRX"
            item_array << { :nombrecampo => "TIPO_TRX", :valorcampo => tipo_tx }
          end
          
          body = { 
            :entrada => {
              "tipo-tx" => tipo_tx,
              :item => item_array
            }
          }
          
          log.debug "Enviando un request al ws: #{body.to_s}"
          
          #Multicaja's webservice proxy
          proxy = Savon::Client.new self.settings[:uri]
          proxy.request.http.open_timeout = self.settings[:open_timeout]
          proxy.request.http.read_timeout = self.settings[:read_timeout]
          response = nil
          begin
            response = proxy.webservice! do |soap|
              soap.namespace = "urn:multicaja_ws"
              soap.body = body
              log.debug "\n \n =====REQUEST XML===#{tipo_tx}===>\n #{format_xml soap.to_xml} \n \n"
              soap
            end
          rescue Timeout::Error => ext
            log.error "Timeout al invocar al ws: #{ext.message}. Params: #{body.to_s}\nSettings de timeout: open #{proxy.request.http.open_timeout}, read #{proxy.request.http.read_timeout}"
            raise Application::BaseWsError, "Timeout al invocar el ws: #{ext.message}. Params: #{body.to_s}"
          rescue Savon::SOAPFault => exs
            log.error "Error al invocar al ws: #{exs.message}. Params: #{body.to_s}"
            raise Application::BaseWsError, "SOAPFault al invocar el ws: #{exs.message}. Params: #{body.to_s}"
          rescue Savon::HTTPError => exh
            log.error "Error al invocar al ws: #{exh.message}. Params: #{body.to_s}"
            raise Application::BaseWsError, "HTTPError al invocar el ws: #{exs.message}. Params: #{body.to_s}"
          end
          # se pasa la respuesta a un hash y se chequea que venga el arreglo de items
          result = response.to_hash
          log.debug "\n \n =====RESPONSE XML ====#{tipo_tx}===>\n #{format_xml response.to_xml} \n \n"
          log.debug "Respuesta del ws: #{result.to_s}"
          if response.nil? or not result.key?(:salida_estandar) or result[:salida_estandar].nil? or not result[:salida_estandar].key?(:item)
            raise Application::BaseWsError, "La respuesta del ws no es valida o no esta completa: #{response.to_s}"
          end
          # en vez de un arreglo de hashes individuales, se retorna un hash con pares :nombrecampo => :valorcampo
          asoc_arr = Hash.new
          asoc_arr[:request] = params
          result[:salida_estandar][:item].each do |par|
            asoc_arr[par[:nombrecampo]] = par[:valorcampo]
          end
          asoc_arr
        end
     
        def format_xml(xml)
          formatted = ""
          # Add Newlines
          xml = xml.gsub( /(>)(<)(\/*)/ ) { "#$1\n#$2#$3" }
          # Add Indents
          pad = 0
          xml.split( "\n" ).each do |node|
            # check various tag states
            indent = 0
            if node.match( /.+<\/\w[^>]*>$/ ) # open and closing on the same line
              indent = 0
            elsif node.match( /^<\/\w/ ) # closing tag
              pad -= 1 unless pad == 0
            elsif node.match( /^<\w[^>]*[^\/]>.*$/ ) # opening tag
              indent = 1
            else
              indent = 0
            end
            formatted << "\t" * pad + node + "\n"
            pad += indent
          end
          formatted
        end

      end # ClassMethods
    
    end # WebserviceClient
  end
end
