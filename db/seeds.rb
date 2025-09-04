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

# More products
blueberry_pancakes = Product.find_or_create_by!(name: "Blueberry Pancakes", user: manager)
pancake_ingredients = [ "Flour", "Milk", "Eggs", "Blueberries", "Baking Powder", "Sugar", "Butter" ]
pancake_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: blueberry_pancakes)
end

lemon_bars = Product.find_or_create_by!(name: "Lemon Bars", user: head)
lemon_ingredients = [ "Flour", "Sugar", "Butter", "Eggs", "Lemon Juice", "Lemon Zest", "Baking Powder" ]
lemon_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: lemon_bars)
end

cinnamon_rolls = Product.find_or_create_by!(name: "Cinnamon Rolls", user: manager)
cinnamon_ingredients = [ "Flour", "Milk", "Yeast", "Sugar", "Butter", "Cinnamon", "Salt", "Eggs" ]
cinnamon_ingredients.each do |ingredient_name|
  Ingredient.find_or_create_by!(name: ingredient_name, product: cinnamon_rolls)
end

puts "Created #{Ingredient.count} ingredients"

# Create machines
puts "Creating machines..."

oven1 = Machine.find_or_create_by!(name: "Oven 1", line: 1, status: :inactive, allocation: :production)
mixer1 = Machine.find_or_create_by!(name: "Mixer 1", line: 1, status: :inactive, allocation: :production)
packaging1 = Machine.find_or_create_by!(name: "Packaging Machine 1", line: 1, status: :inactive, allocation: :packing)
testing1 = Machine.find_or_create_by!(name: "Testing Station 1", line: 2, status: :inactive, allocation: :testing)
oven2 = Machine.find_or_create_by!(name: "Oven 2", line: 2, status: :inactive, allocation: :production)

puts "Created #{Machine.count} machines"

# Create machine checking questions for each machine
puts "Creating machine checking questions..."

# Oven 1 checking questions
MachineChecking.find_or_create_by!(machine: oven1, checking_name: "Temperature Check") do |check|
  check.checking_type = :option
  check.checking_value = "Below 150°C, 150-200°C, 200-250°C, Above 250°C"
end

MachineChecking.find_or_create_by!(machine: oven1, checking_name: "Door Seal Condition") do |check|
  check.checking_type = :option
  check.checking_value = "Good, Fair, Poor, Damaged"
end

MachineChecking.find_or_create_by!(machine: oven1, checking_name: "Cleaning Status") do |check|
  check.checking_type = :option
  check.checking_value = "Clean, Needs Cleaning, Dirty"
end

MachineChecking.find_or_create_by!(machine: oven1, checking_name: "Additional Notes") do |check|
  check.checking_type = :text
  check.checking_value = ""
end

# Mixer 1 checking questions
MachineChecking.find_or_create_by!(machine: mixer1, checking_name: "Mixing Speed") do |check|
  check.checking_type = :option
  check.checking_value = "Low (1-3), Medium (4-6), High (7-10)"
end

MachineChecking.find_or_create_by!(machine: mixer1, checking_name: "Bowl Condition") do |check|
  check.checking_type = :option
  check.checking_value = "Excellent, Good, Fair, Needs Replacement"
end

MachineChecking.find_or_create_by!(machine: mixer1, checking_name: "Blade Sharpness") do |check|
  check.checking_type = :option
  check.checking_value = "Sharp, Acceptable, Dull, Very Dull"
end

MachineChecking.find_or_create_by!(machine: mixer1, checking_name: "Maintenance Notes") do |check|
  check.checking_type = :text
  check.checking_value = ""
end

# Packaging Machine 1 checking questions
MachineChecking.find_or_create_by!(machine: packaging1, checking_name: "Seal Quality") do |check|
  check.checking_type = :option
  check.checking_value = "Perfect, Good, Fair, Poor"
end

MachineChecking.find_or_create_by!(machine: packaging1, checking_name: "Packaging Speed") do |check|
  check.checking_type = :option
  check.checking_value = "Normal, Slow, Fast, Irregular"
end

MachineChecking.find_or_create_by!(machine: packaging1, checking_name: "Material Feed") do |check|
  check.checking_type = :option
  check.checking_value = "Smooth, Occasional Jam, Frequent Jams, Blocked"
end

MachineChecking.find_or_create_by!(machine: packaging1, checking_name: "Operational Issues") do |check|
  check.checking_type = :text
  check.checking_value = ""
end

# Testing Station 1 checking questions
MachineChecking.find_or_create_by!(machine: testing1, checking_name: "Calibration Status") do |check|
  check.checking_type = :option
  check.checking_value = "Calibrated, Needs Calibration, Out of Calibration"
end

MachineChecking.find_or_create_by!(machine: testing1, checking_name: "Test Accuracy") do |check|
  check.checking_type = :option
  check.checking_value = "Accurate, Minor Deviation, Major Deviation, Unreliable"
end

MachineChecking.find_or_create_by!(machine: testing1, checking_name: "Equipment Condition") do |check|
  check.checking_type = :option
  check.checking_value = "Excellent, Good, Fair, Poor"
end

MachineChecking.find_or_create_by!(machine: testing1, checking_name: "Testing Observations") do |check|
  check.checking_type = :text
  check.checking_value = ""
end

# Oven 2 checking questions
MachineChecking.find_or_create_by!(machine: oven2, checking_name: "Temperature Check") do |check|
  check.checking_type = :option
  check.checking_value = "Below 150°C, 150-200°C, 200-250°C, Above 250°C"
end

MachineChecking.find_or_create_by!(machine: oven2, checking_name: "Maintenance Required") do |check|
  check.checking_type = :option
  check.checking_value = "Minor Repair, Major Repair, Parts Replacement, Complete Overhaul"
end

MachineChecking.find_or_create_by!(machine: oven2, checking_name: "Safety Check") do |check|
  check.checking_type = :option
  check.checking_value = "Safe to Operate, Caution Required, Do Not Operate, Emergency Stop"
end

MachineChecking.find_or_create_by!(machine: oven2, checking_name: "Maintenance Details") do |check|
  check.checking_type = :text
  check.checking_value = ""
end

puts "Created #{MachineChecking.count} machine checking questions"

# Create some Prepare records for testing
puts "Creating unit batches and prepare records..."

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

puts "\nLogin credentials for testing:"
puts "  Worker: worker@factory.com / password123"
puts "  Tester: tester@factory.com / password123"
puts "  Supervisor: supervisor@factory.com / password123"
puts "  Manager: manager@factory.com / password123 (can create products)"
puts "  Head: head@factory.com / password123 (can create products)"
