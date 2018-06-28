require 'pstore'

require 'pry'

module Aws
  module SiteMonitor
    module PstoreRecord
      extend ::ActiveSupport::Concern

      included do
        table_name self.name.demodulize.downcase.pluralize
      end

      module ClassMethods
        def [](k)
          instance_variable_get(:"@_#{k}")
        end

        def primary_key(key)
          @_primary_key = key
        end

        def table_name(value)
          @_table_name = value
        end

        def database
          @_database ||= ::PStore.new("#{self[:table_name]}.pstore")
        end

        def create(attributes={})
          record = new(attributes)
          record.save
        end

        def all
          database.transaction(true) do  # begin read-only transaction
            database.roots.map do |data_root_name|
              # binding.pry
              record = database[data_root_name]
              record.symbolize_keys!
              new(**record.symbolize_keys)
            end
          end
        end

        def find_by(**options)
          all.find{ |record| options.all?{|k,v| record[k] == v } }
        end
      end

      def [](k)
        instance_variable_get(:"@#{k}")
      end

      def []=(k,v)
        instance_variable_set(:"@#{k}", v)
      end

      def initialize(id: ::SecureRandom.hex(16), **_attributes)
        self['id'] = id

        _attributes.each_pair do |k,v|
          self[k] = v
        end
      end

      def attributes
        instance_variables.each_with_object({}) do |k, obj|
          key = k[1,k.length]
          obj[key] = self[key]
        end.symbolize_keys
      end

      def destroy
        self.class.database.transaction do
          self.class.database.delete(self[:id])
        end

        true
      end


      def save
        records = self.class.database

        records.transaction do
          records[@id] = self.attributes.symbolize_keys
          records.commit
        end
      end
    end
  end
end
