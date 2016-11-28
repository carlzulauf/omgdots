module JsonObject
  class Field
    attr_accessor :name, :type, :options

    def initialize(name, type, **options)
      self.name     = name
      self.type     = type
      self.options  = options
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
  end

  extend ActiveSupport::Concern

  included do
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

    def field(name, type, **options)
      Field.new(name, type, options).tap do |f|
        fields << f
        define_methods_for(f)
      end
    end

    def define_methods_for(field)
      generic_reader(field)
      case field.type
      when Symbol
        send("#{field.type}_writer", field)
      when String
        object_writer(field)
      end
    end

    def generic_reader(field)
      define_method(field.name) { object[field.name.to_s] }
    end

    def define_writer(f)
      define_method("#{f.name}=") do |value|
        object[f.name.to_s] = yield(value)
      end
    end

    def string_writer(f)
      define_writer(f) do |value|
        value ? value.to_s : nil
      end
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

    def integer_writer(f)
      define_writer(f) do |value|
        coerce_numeric(value, :to_i)&.round
      end
    end

    def boolean_writer(f)
      define_writer(f) do |value|
        case value
        when String, Symbol then !!(value =~ /t(rue)?|y(es)?|on/i)
        else !!value
        end
      end
    end

    def float_writer(f)
      define_writer(f) do |value|
        coerce_numeric(value, :to_f)&.to_f
      end
    end

    def time_writer(f)
      define_writer(f) do |value|
        case value
        when Time then value
        when String then Time.parse(value)
        end
      end
    end

    def object_writer(f)
      klass = nil
      define_writer(f) do |value|
        klass ||= f.type.constantize # doing this here so it's lazily evaluated
        case value
        when klass then value
        when nil then nil
        else klass.new(value)
        end
      end
    end
  end
end
