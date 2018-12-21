# frozen_string_literal: false

require 'csv'

module LexisNexis
  class Importer < BaseImporter
    include ProcessRecordAfterBatchInsert
    def initialize
      host = ENV['LEXIS_NEXIS_HOST']
      user_name = ENV['LEXIS_NEXIS_USERNAME']
      password = ENV['LEXIS_NEXIS_PASSWORD']

      @sftp = SFTPService.new(host, user_name, password)
      @unique_key = 'vin'
      @model = ::LexisNexis::Registration
      @batch_size = 100
      @current_batch = []
      @sidekiq_instance_variables = {}
      @default_format_string = '%m/%d/%Y'
      @overridden_format_strings = {}
    end

    def find_and_download_file
      files = []
      LexisNexis::RequestList.all.where(request_status: 'sent', imported_at: nil).each do |request_list|
        @request_list = request_list
        %w[_p _v].each do |ending|
          file = request_list.file_name.gsub(/.txt/, "#{ending}\\0")
          files << @sftp.download_to_temp(file)
        end
      end
      files
    end

    def csv_options
      {
        headers: true,
        col_sep: "\t",
        header_converters: -> (header) { self.convert_header(header) }
      }
    end

    def convert_header(header)
      header.to_s.underscore.tr('#', '_number').tr('birthdate', 'birth_date').tr(' ', '_')
    end

    def retrieve_data
      self.find_and_download_file.each do |file|
        file_type = file.original_filename.downcase.include?('_p') ? 'P' : 'V'
        CSV.foreach(file, self.csv_options) do |row|
          row_hash = row.to_h.merge(registration_request_list_id: @request_list.id, file_type: file_type).compact
          self.process_record(row_hash) if row_hash.present?
        end
      end
      @request_list.update(imported_at: Date.current)
    end
  end
end
