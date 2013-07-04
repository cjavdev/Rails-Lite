class MassObject
  
  @attributes = []
  def self.set_attrs(*attributes)
    @attributes = attributes
    attributes.each do |attribute|
      attr_accessor "#{attribute}"
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    new_objs = []
    results.each do |result|
      new_objs << self.new(result)
    end
    new_objs
  end

  def initialize(params = {})
    params.each do |attribute, val|
      if self.class.attributes.include?(attribute.to_sym)
        send("#{attribute}=", val) 
      else
        raise "mass assignment to unregistered attribute #{attribute}"
      end
    end
  end
end
