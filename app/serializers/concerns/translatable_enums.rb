module TranslatableEnums
  extend ActiveSupport::Concern

  class_methods do

    def translatable_enums(*enum_fields)
      @translatable_enum_fields = enum_fields
      
      enum_fields.each do |enum_field|
        define_method "translated_#{enum_field}" do
          translate_enum_value(enum_field)
        end
      end
      
      enum_fields.map { |field| "translated_#{field}".to_sym }
    end
    
    def translated_enum_fields
      @translatable_enum_fields ||= []
      @translatable_enum_fields.map { |field| "translated_#{field}".to_sym }
    end
  end

  private

  def translate_enum_value(enum_field)
    return nil unless object.respond_to?(enum_field)
    
    enum_value = object.send(enum_field)
    return nil if enum_value.blank?

    model_name = object.class.name.underscore
    pluralized_enum = enum_field.to_s.pluralize
    
    I18n.t("activerecord.attributes.#{model_name}.#{pluralized_enum}.#{enum_value}", default: enum_value.humanize)
  end
end