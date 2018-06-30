# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Faker::Config.locale = :ja
100.times do |_n|
  title = Faker::Lorem.sentence
  description = Faker::Lorem.paragraph
  status = [0, 1, 2].sample
  priority = [-1, 0, 1].sample
  Task.create!(title: title, description: description, status: status,
               priority: priority)
end
