# frozen_string_literal: true

require 'net/ssh'
require 'net/sftp'
require 'tempfile'
require 'csv'

module LexisNexis
  class Service
    def initialize(store)
      host = ENV['LEXIS_NEXIS_HOST']
      user_name = ENV['LEXIS_NEXIS_USERNAME']
      password = ENV['LEXIS_NEXIS_PASSWORD']

      @sftp = Net::SFTP.start(host, user_name, password: password)
      @store = store
    end

    def create_send_list_items(registrations)
      request_list = create_request_list
      create_request_items(registrations, request_list)
      send_registration_items(request_list)
    end

    def create_request_list
      file_name = "#{@store.name.downcase.tr(' ', '_')}_#{Time.current.to_i}.txt"
      LexisNexis::RequestList.create(file_name: file_name, store_id: @store.id)
    end

    def create_request_items(registrations, request_list)
      registrations.each do |registration|
        LexisNexis::RequestItem.create(
          registration.slice(:first_name, :last_name, :city, :state, :zip)
                      .merge(registration.slice(:year, :make, :model, :vin).transform_keys { |k| "auto_#{k}" })
                      .merge(
                        address: registration[:street],
                        aoi: @store.name,
                        registration_request_list_id: request_list.id,
                        current_owner_status: false,
                        store_id: @store.id
                      )
                      .symbolize_keys
        )
      end
      request_list.update(total_requested_registrations: registrations.length)
    end

    def send_registration_items(request_list)
      %i[_p _v].map do |ending|
        tempfile_path = Tempfile.new(request_list.file_name.gsub(/.txt/, "#{ending}\\0")).path

        CSV.open(tempfile_path, 'wb', headers: true) do |csv|
          csv << request_list.class.column_names
          request_list.registration_request_items.each do |item|
            csv << item.attributes.values
          end
        end

        @sftp.upload tempfile_path, "/incoming/#{tempfile_path}"
      end
      request_list.update(request_status: 'sent')
    end
  end
end
