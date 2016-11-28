module JsonObject
  class Field
    attr_reader :name, :type, :options

    def initialize(name, type, **options)
      @name     = name
      @type     = type
      @options  = options
    end

    def default?
      options.key?(:default)
    end

    def default(object)
      v = options[:default]
      if v.is_a? Symbol
        object.send(v)
      elsif v.respond_to? :to_proc
        object.instance_exec(&v)
      else
        v
      end
    end

    def klass
      return if type.is_a?(Symbol)
      @klass ||= type.constantize
    end
  end

  extend ActiveSupport::Concern

  included do
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    attr_reader :object
  end

  def initialize(attributes = {})
    @object = {}
    assign_attributes(attributes)
    assign_defaults
  end

  def assign_attributes(attributes)
    attributes.each do |field, value|
      meth = "#{field}="
      if respond_to? meth
        send(meth, value)
      else
        object[field.to_s] = value
      end
    end
  end

  def assign_defaults
    self.class.fields.select(&:default?).each do |field|
      send("#{field.name}=", field.default(self)) if send(field.name) == nil
    end
  end

  def as_json(*)
    object
  end

  class_methods do
    def fields
      @fields ||= []
    end

    def collections
      @collections ||= []
    end

    def field(name, type, **options)
      Field.new(name, type, options).tap do |f|
        fields << f
        define_methods_for(f)
      end
    end

    def many(name, type, **options)
      Field.new(name, type, options).tap do |f|
        f.options[:default] ||= []
        collections << f
        fields << f
        generic_reader(f)
        collection_writer(f)
      end
    end

    def define_methods_for(field)
      generic_reader(field)
      case field.type
      when Symbol
        send("#{field.type}_writer", field)
      when String
        typed_writer(field)
      end
    end

    def generic_reader(f)
      define_method(f.name) { object[f.name.to_s] }
    end

    def define_writer(f)
      define_method("#{f.name}=") do |value|
        object[f.name.to_s] = yield(value)
      end
    end

    def coerce_hash(value)
      value&.stringify_keys
    end

    def hash_writer(a_field)
      define_writer(a_field) { |v| coerce_hash(v) }
    end
    alias_method :object_writer, :hash_writer

    def coerce_array(value)
      value&.to_a
    end

    def array_writer(f)
      define_writer(f) { |v| coerce_array(v) }
    end

    def coerce_string(value)
      value ? value.to_s : nil
    end

    def string_writer(f)
      define_writer(f) { |v| coerce_string(v) }
    end

    def coerce_numeric(value, from_str = :to_i)
      case value
      when String
        digits = value.scan(/[\d\.]+/)
        digits.any? ? digits.join.send(from_str) : nil
      when Numeric
        value
      else
        nil
      end
    end

    def coerce_integer(value)
      coerce_numeric(value, :to_i)&.round
    end

    def integer_writer(f)
      define_writer(f) { |value| coerce_integer(value) }
    end

    def coerce_float(value)
      coerce_numeric(value, :to_f)&.to_f
    end

    def float_writer(f)
      define_writer(f) { |value| coerce_float(value) }
    end

    def coerce_boolean(value)
      case value
      when String, Symbol then !!(value =~ /t(rue)?|y(es)?|on/i)
      else !!value
      end
    end

    def boolean_writer(a_field)
      define_writer(a_field) { |value| coerce_boolean(value) }
    end

    def coerce_time(value)
      case value
      when Time then value
      when String then Time.parse(value)
      end
    end

    def time_writer(f)
      define_writer(f) { |v| coerce_time(v) }
    end

    def coerce_for_field(value, field)
      case field.type
      when Symbol then send("coerce_#{field.type}", value)
      else coerce_to_class(value, field.klass)
      end
    end

    def coerce_to_class(value, klass)
      case value
      when klass then value
      when nil then nil
      else klass.new(value)
      end
    end

    def collection_writer(f)
      define_writer(f) do |values|
        values&.map { |value| coerce_for_field(value, f) }
      end
    end

    def typed_writer(f)
      define_writer(f) { |value| coerce_to_class(value, f.klass) }
    end

  end
end
