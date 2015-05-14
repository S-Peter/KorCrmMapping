class Relationship < ActiveRecord::Base #Verknüpfung
	belongs_to :relation
	belongs_to :domain, class_name: "Entity", foreign_key: "from_id"
	belongs_to :range, class_name: "Entity", foreign_key: "to_id"
end
