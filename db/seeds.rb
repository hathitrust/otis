# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

raise "Not for production use" if Rails.env.production?

require 'faker'

10.times do
  u = HTUser.new(
    userid: Faker::Internet.email,
    displayname: Faker::Name.name,
    email: Faker::Internet.email,
    activitycontact: Faker::Internet.email,
    approver: Faker::Internet.email,
    authorizer: Faker::Internet.email,
    usertype: ['staff','external','student'].sample,
    role: ['corrections','cataloging','ssdproxy','crms','quality','staffdeveloper','staffsysadmin','replacement','ssd'].sample,
    access: ['total','normal'].sample,
    expires: Faker::Time.forward,
    expire_type: ['expiresannually','expiresbiannually','expirescustom90','expirescustom60'].sample,
    mfa: 0,
    identity_provider: Faker::Internet.url
  )
  u.iprestrict = Faker::Internet.ip_v4_address
  u.save

end
