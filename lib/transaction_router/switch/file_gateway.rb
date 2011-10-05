# coding: utf-8
module TransactionRouter
  class Switch
    class FileGateway
      extend ActiveSupport::Concern

      module ClassMethods
        # Responde la transacción con un archivo
        def file(transaction_name, params)
          filename = file_name transaction_name
          if File.exists? filename
            response = return_file filename, params
          else
            response = return_error transaction_name
          end
          response
        end

        def file_name(transaction_name)
          op = trx_options transaction_name
          filename = op[:filename] || "#{transaction_name.upcase}.xml"
          relpath = op[:filepath] || self.settings[:relative_file_path]
          "#{self.settings[:root_path]}/#{relpath}/#{filename}"
        end

        def return_file(filename, params)
          # Archivo de Emulacion de respuesta del ws. Debe quitarse 'ns:', 'soap envelope' del archivo xml que se generará para emular la respuesta.
          file = File.open filename
          xml = file.read
          response = Hash.from_xml xml
          # Se formatea la respuesta a nombrecampo => valorcampo
          asoc_arr = Hash.new
          asoc_arr[:request] = params
          response["salida_estandar"]["item"].each do |par|
            asoc_arr[par["nombrecampo"]] = par["valorcampo"]
          end
          return asoc_arr
        end

        def return_error(transaction_name)
          op = trx_options transaction_name
          exception = op[:on_file_not_found] || self.settings[:on_file_not_found_exception]
          raise exception, "Transacción configurada para retornar archivo, pero sin archivo de respuesta"
        end

      end # ClassMethods
    end
  end
end 
