module ApplicationHelper
  def paginate(record, page, per_page, serializer = nil, current_user = nil, **extra_params)
    page = (page.presence || 1).to_i
    per_page = (per_page.presence || 10).to_i
  
    is_relation = record.is_a?(ActiveRecord::Relation)
  
    total_count = is_relation ? record.count : record.size
    total_pages = per_page > 0 ? (total_count / per_page.to_f).ceil : 0
  
    if is_relation
      data = record.offset(per_page * (page - 1)).limit(per_page).uniq
    else
      start_index = per_page * (page - 1)
      data = record.slice(start_index, per_page) || []
    end
    
    serialized_data = data 
    if serializer
      if current_user.present?
        serialized_data = ActiveModel::SerializableResource.new(data, each_serializer: serializer, scope: { current_user: current_user })
      else
        serialized_data = ActiveModel::SerializableResource.new(data, each_serializer: serializer)
      end
    end

    {
      data: serialized_data, 
      total_count: total_count, 
      total_pages: total_pages
    }.merge!(extra_params)
  end

  def search_bar(record, terms, params)
    return record if terms.blank?
    
    terms = URI::decode_uri_component(terms)

    if params.kind_of?(Array)
      query = ""
      params.each{|param| query.concat(" OR unaccent(CAST(#{param} as varchar(1000))) ILIKE unaccent(:terms)")}
      query = query.sub!(" OR ", "")
      
      record.where(query, terms: "%#{terms}%") 
    else
      record.where("unaccent(CAST(#{params} as varchar(1000))) ILIKE unaccent(?)", "%#{terms}%") 
    end
  end

  def self.enum_options(entity, type)
    model = entity.classify.safe_constantize
    empty_model = model.nil?
    return {
      error?: empty_model,
      message: "A entidade #{entity} não foi encontrada.",
      options: []
    } if empty_model

    model_not_exists = !(model < ApplicationRecord)
    return {
      error?: model_not_exists,
      message: "A entidade #{entity} não é um model válido.",
      options: []
    } if model_not_exists

    enums = model.defined_enums.keys
    type_not_exists = !enums.include?(type)
    return {
      error?: type_not_exists,
      message: "O enum #{type} não foi encontrado, os tipos disponiveis são: #{enums.join(', ')}",
      options: []
    } if type_not_exists
    
    pluralized_type = type.pluralize
    options = model.send(pluralized_type).map { |key, _| { value: key, label: I18n.t("activerecord.attributes.#{entity}.#{pluralized_type}.#{key}") } }
    {
      error?: type_not_exists,
      options: options
    }
  end

  def file_info(file)
    return nil unless file.attached?
    {
      url: file.url,
      filename: file.filename.to_s
    }
  end
end
