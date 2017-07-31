#---*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*---#
#---*     THE ULTIMATE BIRTHDAY REMINDER APP     *---#
#---*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*---#

#----Methods and Variables----#

  #--includes a gem that lets Ruby play with SQLite3
require 'sqlite3'

  #--makes an SQLite3 database
db = SQLite3::Database.new("birthday.db")
db.results_as_hash = true

  #--makes a string to be used as an SQL command
create_table_cmd = <<-SQL
  CREATE TABLE IF NOT EXISTS people (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255),
  month INT,
  day INT,
  day_of_year INT
  )
SQL

  #--uses above string to create SQLite3 database
db.execute(create_table_cmd)

  #--creates a data structure, alphabetized by first name
people = db.execute("SELECT * FROM people ORDER BY name")


  #--needed to calculate the day of the year as a simple integer
$days_before_month_number = {
  1 => 0,
  2 => 31,
  3 => 59,
  4 => 90,
  5 => 120,
  6 => 151,
  7 => 181,
  8 => 212,
  9 => 243,
  10 => 273,
  11 => 304,
  12 => 334
}

  #--clears the terminal window
def clear
  500.times {puts " "}
end

  #--makes my ugly driver code a *little* less ugly
def app_display
  puts "*-*-*-The Ultimate Birthday Reminder App-*-*-*"
  puts " "
end

  #--shows birthdays that fall within the next 40
  #--days, sorted by closest to today's date
    #--also handles the December/January edge case by using
    #--a temporary array to store birthday notifications
      #--(otherwise, they'd print above December birthdays)
def upcoming_birthdays(db, current_month, current_day)
  puts "*Today's date: #{current_month}/#{current_day}"
  puts " "
  puts "*Upcoming birthdays:"
  puts " "
  people_sorted_by_bday = db.execute("SELECT * FROM people ORDER BY day_of_year")
  holds_january_birthdays = []
  people_sorted_by_bday.each do |person|
    if person['day_of_year'] == $current_day_of_year
      puts "  *#{person['month']}/#{person['day']}: #{person['name']}'s birthday is TODAY!"
    elsif person['day_of_year'] > $current_day_of_year && person['day_of_year'] < $current_day_of_year + 40
      puts "  *#{person['month']}/#{person['day']}: #{person['name']}"
    elsif $current_day_of_year > 350 && person['day_of_year'] < 31
      holds_january_birthdays << "  *#{person['month']}/#{person['day']}: #{person['name']}"
    end
  end
  holds_january_birthdays.each do |birthday_text|
    puts birthday_text
  end
end

  #--displays contacts in alphabetical order, along with their birthdays
def view_contacts(people)
  people.each do |person|
    puts "  *#{person['name']}: #{person['month']}/#{person['day']}"
  end
end

  #--adds a contact to the people database
def add_contact (db)
  print "Full name of contact you'd like to add: "
    new_contact = gets.chomp
  print "Month of #{new_contact}'s birthday (as an integer): "
    new_month = gets.chomp.to_i
  print "Day of #{new_contact}'s birthday (as an integer): "
    new_day = gets.chomp.to_i
    new_day_of_year = $days_before_month_number[new_month] + new_day
    db.execute("INSERT INTO people (name, month, day, day_of_year) VALUES (?, ?, ?, ?)", [new_contact, new_month, new_day, new_day_of_year])
end

  #--modifies name and/or birthday of a single contact
def modify_contact(db, people)
    #--ensures valid input
  valid_input = false
  while valid_input == false
    print "Full name of contact to modify (or 'cancel'): "
      name_entered = gets.chomp
      people.each do |person|
        if name_entered == "cancel"
          valid_input = true
        elsif person['name'] == name_entered
          valid_input = true
        end
      end
  end
    #--modifies name
  name_update_finalized = false
  while name_update_finalized == false && name_entered != "cancel"
    print "Change #{name_entered}'s name? (y/n) "
      response = gets.chomp
      if response == "y"
        print "New full name to be stored for this contact: "
        new_name = gets.chomp
        db.execute("UPDATE people SET name='#{new_name}' WHERE name='#{name_entered}'")
        name_update_finalized = true
        name_changed = true
      elsif response == "n"
        name_update_finalized = true
        name_changed = false
      end
  end
    #--modifiesy birthday
  birthday_update_finalized = false
  while birthday_update_finalized == false && name_entered != "cancel"
    print "Change this contact's birthday? (y/n) "
      response = gets.chomp.downcase
      if response == "y"
        if name_changed == true
          print "New month to be stored for #{new_name}'s birthday (as integer): "
          new_month = gets.chomp.to_i
          print "New day to be stored for #{new_name}'s birthday (as integer): "
          new_day = gets.chomp.to_i
          new_day_of_year = $days_before_month_number[new_month] + new_day
          db.execute("UPDATE people SET month=#{new_month}, day=#{new_day}, day_of_year=#{new_day_of_year} WHERE name='#{new_name}'")
          birthday_update_finalized = true
        elsif name_changed == false
          print "New month to be stored for #{name_entered}'s birthday (as integer): "
          new_month = gets.chomp.to_i
          print "New day to be stored for #{name_entered}'s birthday (as integer): "
          new_day = gets.chomp.to_i
          new_day_of_year = $days_before_month_number[new_month] + new_day
          db.execute("UPDATE people SET month=#{new_month}, day=#{new_day}, day_of_year=#{new_day_of_year} WHERE name='#{name_entered}'")
          birthday_update_finalized = true
        end
      elsif response == "n"
        birthday_update_finalized = true
      end
  end
end

  #--deletes a contact, ensures valid input
def delete_contact(db, people)
  valid_input = false
  while valid_input == false
  print "Full name of contact to delete (or 'cancel'): "
    text_entered = gets.chomp
    people.each do |person|
      if text_entered == "cancel"
        valid_input = true
      elsif person['name'] == text_entered
        confirmed = false
        while confirmed == false
          print "Permantely delete #{person['name']}? (y/n) "
          delete_confirm = gets.chomp
          if delete_confirm == "y"
            db.execute("DELETE FROM people WHERE name = '#{text_entered}'")
            puts "#{person['name']} was deleted."
            confirmed = true
            valid_input = true
          elsif delete_confirm == "n"
            confirmed = true
            valid_input = true
          end
        end
      end
    end
  end
end


#----Driver Code----#
clear
puts "Welcome to The Ultimate Birthday Reminder App 1.0!"
puts " "
puts "Please enter today's date, using digits."
print "  Month: "
current_month = gets.chomp.to_i
print "  Day: "
current_day = gets.chomp.to_i
$current_day_of_year = $days_before_month_number[current_month] + current_day
clear
app_display

not_done = true
while not_done
  puts " "
  print "Enter 'upcoming', 'all', 'add contact', 'modify contact', 'delete contact' or 'exit': "
  response = gets.chomp.downcase
    if response == "upcoming"
      clear
      app_display
      upcoming_birthdays(db, current_month, current_day)
    elsif response == "all"
      clear
      app_display
      view_contacts(people)
    elsif response == "add contact"
      clear
      app_display
      add_contact(db)
      people = db.execute("SELECT * FROM people ORDER BY name")
    elsif response == "modify contact"
      clear
      app_display
      modify_contact(db, people)
      people = db.execute("SELECT * FROM people ORDER BY name")
    elsif response == "delete contact"
      clear
      app_display
      delete_contact(db, people)
      people = db.execute("SELECT * FROM people ORDER BY name")
    elsif response == "exit"
      not_done = false
      clear
      puts "Thanks for using The Ultimate Birthday Reminder App."
    else
      clear
      app_display
      puts "That's not a valid input."
    end
end