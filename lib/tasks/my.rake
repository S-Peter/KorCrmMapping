desc "does something cool"
task :doit => :environment do
  p Relationship.
    joins("JOIN entities as froms on froms.id = relationships.from_id").
    joins("JOIN entities as tos on tos.id = relationships.to_id").
    group("froms.kind_id","relationships.relation_id" , "tos.kind_id").
    count
end
