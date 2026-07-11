class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  has_paper_trail

  def serializable_hash(options=nil)
    "#{self.class.to_s}Serializer".constantize.new(self).serializable_hash(options)
  end

  def self.dependent_discard(dependent_class_name)
    after_discard do 
      self.class.reflect_on_association(dependent_class_name).macro == :has_one ? self.send(dependent_class_name)&.discard : self.send(dependent_class_name).discard_all
    end
    
    after_undiscard do 
      self.class.reflect_on_association(dependent_class_name).macro == :has_one ? self.send(dependent_class_name)&.undiscard : self.send(dependent_class_name).unscoped.undiscard_all
    end
  end
end
