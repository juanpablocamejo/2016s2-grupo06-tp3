require 'mongo'
require_relative 'mongo_db'
require_relative 'dynamic_finders'
require_relative 'errors'

module MongoDocument

  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
    base.initialize_class
  end

############ INSTANCE METHODS ############
  module InstanceMethods

    def to_hash
      hash ={}
      self.class.fields.each { |k| hash[k.to_s]=self.send(k) }
      hash
    end

# ====== SAVE / UPDATE / REMOVE ====== #
    def save
      ## before_save hook ##
      before_save()

      if self._id.nil?
        self._id=BSON::ObjectId.new
      end
      self.class.db_collection.insert_one(to_hash)

      ## after_save hook ##
      after_save()
      self
    end

    def update
      filter = {:_id => _id}
      upd = to_hash.select { |k, v| k != :_id }
      self.class.db_collection.update_one(filter, upd)
      self
    end

    def remove
      self.class.db_collection.delete_one({:_id => _id})
      self._id = nil
      self
    end

    def after_save
    end

    def before_save
    end
  end


############ CLASS METHODS ############
  module ClassMethods

    def initialize_class
      @fields={}
      @collection_name = default_collection_name
      field :_id
      @on_populate_proc = nil
      @validators = {
          :required => Proc.new do |is_req, f_value, f_type|
            raise Error::RequiredFieldError if is_req and f_value.nil?
          end
      }
    end

# ====== QUERYS ====== #

    include DynamicFinders

    def count
      db_collection.count
    end

    def find(filter=nil)
      col_view = db_collection.find(filter)
      if col_view.count==0
        []
      else
        results = []
        col_view.each { |d| results.push from_document(d) }
        results
      end
    end


# ====== COLLECTION ====== #

    def collection(name)
      @collection_name = name
    end

    def collection_name
      @collection_name.to_s
    end

    def default_collection_name
      "#{name[0].downcase}#{name[1..-1]}s"
    end

# @return [MongoDB::Collection]
    def db_collection
      MongoDB.client.database.collection(collection_name)
    end

# ====== FIELDS / VALIDATIONS ====== #

    def field(field_name, field_type=Object, field_validations={})
      if !@fields.include?(field_name)
        @fields[field_name.to_sym] = field_type
        define_method(field_name) { instance_variable_get("@#{field_name}") }
        define_method(("#{field_name}=").to_sym) do |field_value|
          self.class.validate(field_value, field_type, field_validations)
          instance_variable_set("@#{field_name}", field_value)
        end
      end
    end

    def validate(field_value, field_type, field_validations)
      raise Error::FieldTypeError unless field_value.nil? or field_value.is_a? field_type
      field_validations.each {
          |validation_key, validation_arg|
        @validators[validation_key].call(validation_arg, field_value, field_type)
      }
    end

    def fields
      @fields.keys
    end

# ====== DOCUMENT MAPPING ====== #

    def from_document(d)
      an_instance = self.new
      d.each { |k, v| an_instance.send("#{k}=", v) }

      if !@on_populate_proc.nil?
        an_instance.instance_eval(&@on_populate_proc)
      end
      an_instance
    end

## on_populate hook ##
    def on_populate(&bk)
      @on_populate_proc = bk
    end
  end

end

