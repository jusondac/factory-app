# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create users for each role
puts "Creating users for each role..."

# Worker (role: 0)
worker = User.find_or_create_by!(email_address: "worker@factory.com") do |user|
  user.password = "password123"
  user.role = :worker
end

# Tester (role: 1)
tester = User.find_or_create_by!(email_address: "tester@factory.com") do |user|
  user.password = "password123"
  user.role = :tester
end

# Supervisor (role: 2)
supervisor = User.find_or_create_by!(email_address: "supervisor@factory.com") do |user|
  user.password = "password123"
  user.role = :supervisor
end

# Manager (role: 3) - Can create products
manager = User.find_or_create_by!(email_address: "manager@factory.com") do |user|
  user.password = "password123"
  user.role = :manager
end

# Head (role: 4) - Can create products
head = User.find_or_create_by!(email_address: "head@factory.com") do |user|
  user.password = "password123"
  user.role = :head
end

puts "Created #{User.count} users"

# Create products (only managers and heads can create products)
puts "Creating sample products..."

# Products created by manager
chocolate_cake = Product.find_or_create_by!(name: "Chocolate Cake", user: manager)
vanilla_cookies = Product.find_or_create_by!(name: "Vanilla Cookies", user: manager)
strawberry_muffin = Product.find_or_create_by!(name: "Strawberry Muffin", user: manager)

# Products created by head
premium_bread = Product.find_or_create_by!(name: "Premium Bread", user: head)
artisan_pizza = Product.find_or_create_by!(name: "Artisan Pizza", user: head)

puts "Created #{Product.count} products"

# Create ingredients for each product
puts "Creating ingredients for products..."

# Chocolate Cake ingredients
chocolate_ingredients = [ "Dark Chocolate", "Flour", "Sugar", "Eggs", "Butter", "Vanilla Extract", "Baking Powder" ]
chocolate_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: chocolate_cake)
end

# Vanilla Cookies ingredients
cookie_ingredients = [ "Flour", "Sugar", "Butter", "Vanilla Extract", "Eggs", "Baking Soda" ]
cookie_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: vanilla_cookies)
end

# Strawberry Muffin ingredients
muffin_ingredients = [ "Flour", "Sugar", "Strawberries", "Milk", "Eggs", "Baking Powder", "Salt" ]
muffin_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: strawberry_muffin)
end

# Premium Bread ingredients
bread_ingredients = [ "Bread Flour", "Yeast", "Salt", "Water", "Olive Oil", "Honey" ]
bread_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: premium_bread)
end

# Artisan Pizza ingredients
pizza_ingredients = [ "Pizza Dough", "Tomato Sauce", "Mozzarella Cheese", "Basil", "Olive Oil", "Oregano" ]
pizza_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: artisan_pizza)
end

puts "Created #{Ingredient.count} ingredients"

# Create some Prepare records for testing
puts "Creating unit batches and prepare records..."

# Clear existing data to ensure clean state
puts "Clearing existing prepare and unit batch data..."
Prepare.destroy_all
UnitBatch.destroy_all

# Get all products for variety
products = [ chocolate_cake, vanilla_cookies, strawberry_muffin, premium_bread, artisan_pizza ]

# Create 15 prepare records with various statuses and dates
prepare_data = [
  # Today's preparations (some unchecked, some checking)
  { product: chocolate_cake, date: Date.current, status: :unchecked, checked_by: nil },
  { product: vanilla_cookies, date: Date.current, status: :checking, checked_by: worker },
  { product: artisan_pizza, date: Date.current, status: :unchecked, checked_by: nil },

  # Tomorrow's preparations (all unchecked)
  { product: strawberry_muffin, date: Date.current + 1.day, status: :unchecked, checked_by: nil },
  { product: premium_bread, date: Date.current + 1.day, status: :unchecked, checked_by: nil },
  { product: chocolate_cake, date: Date.current + 1.day, status: :unchecked, checked_by: nil },

  # Yesterday's preparations (should be auto-cancelled due to past date)
  { product: vanilla_cookies, date: Date.current - 1.day, status: :checked, checked_by: worker },
  { product: artisan_pizza, date: Date.current - 1.day, status: :cancelled, checked_by: nil },
  { product: strawberry_muffin, date: Date.current - 1.day, status: :checked, checked_by: worker },

  # Day before yesterday (completed and cancelled)
  { product: premium_bread, date: Date.current - 2.days, status: :checked, checked_by: worker },
  { product: chocolate_cake, date: Date.current - 2.days, status: :cancelled, checked_by: nil },

  # Future preparations (next week)
  { product: vanilla_cookies, date: Date.current + 3.days, status: :unchecked, checked_by: nil },
  { product: artisan_pizza, date: Date.current + 4.days, status: :unchecked, checked_by: nil },
  { product: strawberry_muffin, date: Date.current + 5.days, status: :unchecked, checked_by: nil },
  { product: premium_bread, date: Date.current + 6.days, status: :unchecked, checked_by: nil }
]

prepare_data.each_with_index do |data, index|
  # Create unit batch first
  unit_batch = UnitBatch.create!(product: data[:product])

  # Create prepare
  prepare = Prepare.create!(
    unit_batch: unit_batch,
    prepare_date: data[:date],
    created_by: supervisor,
    status: data[:status],
    checked_by: data[:checked_by]
  )

  # If the prepare is checked, mark some ingredients as checked
  if data[:status] == :checked
    prepare.prepare_ingredients.limit(prepare.prepare_ingredients.count).each do |ingredient|
      ingredient.update!(checked: true)
    end
  elsif data[:status] == :checking
    # For checking status, mark some ingredients as checked (partial progress)
    checked_count = prepare.prepare_ingredients.count / 2
    prepare.prepare_ingredients.limit(checked_count).each do |ingredient|
      ingredient.update!(checked: true)
    end
  end

  puts "Created prepare #{index + 1}/#{prepare_data.length}: #{prepare.prepare_id} - #{prepare.product.name} (#{prepare.status})"
end

puts "Created #{UnitBatch.count} unit batches and #{Prepare.count} prepare records"

puts "\n=== Seed Data Summary ==="
puts "Users created:"
User.all.each do |user|
  puts "  #{user.role.capitalize}: #{user.email_address} (ID: #{user.id})"
end

puts "\nProducts created:"
Product.includes(:user).each do |product|
  puts "  #{product.name} (created by #{product.user.role}: #{product.user.email_address})"
  puts "    Ingredients: #{product.ingredients.pluck(:name).join(', ')}"
end

puts "\nPrepares created:"
Prepare.includes({ unit_batch: :product }, :created_by, :checked_by).each do |prepare|
  puts "  #{prepare.prepare_id} - #{prepare.product.name} (#{prepare.prepare_date}) - Status: #{prepare.status}"
  puts "    Unit Batch: #{prepare.unit_batch.unit_id}"
  puts "    Created by: #{prepare.created_by.email_address}"
  puts "    Checked by: #{prepare.checked_by&.email_address || 'None'}"
  puts "    Ingredients: #{prepare.prepare_ingredients.count} (#{prepare.checking_progress})"
end

puts "\nLogin credentials for testing:"
puts "  Worker: worker@factory.com / password123"
puts "  Tester: tester@factory.com / password123"
puts "  Supervisor: supervisor@factory.com / password123"
puts "  Manager: manager@factory.com / password123 (can create products)"
puts "  Head: head@factory.com / password123 (can create products)"
