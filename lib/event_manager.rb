require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_num(phone_num)
  # Omitting any non number chracters & spaces:
  phone_num = phone_num.split('').select { |n| ('0'..'9').include?(n) }.join
  return phone_num = phone_num[1..] if phone_num.to_s.length == 11 && phone_num[0] == 1

  phone_num.to_s.rjust(10, '#')[0..10]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )

    # legislators is an array containing raw legislator objects:
    legislators = legislators.officials

    legislator_names = legislators.map(&:name)

    legislator_names.join(', ')

  # The most standard error types are subclasses of StandardError. A rescue
  # clause without an explicit Exception class will rescue all StandardErrors
  # (and only those).
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def find_peak_hours(hours_hash)
  peak_value = hours_hash.values.max
  # which hours have peak values:
  peak_keys_arr = hours_hash.keys.select { |key| hours_hash[key] == peak_value }

  convert_arr_to_string(peak_keys_arr)
end

def find_peak_days(days_hash)
  # using reduce here just for fun:
  peak_day = days_hash.reduce(0) do |acc, (_k, v)|
    if acc > v
      acc
    else
      v
    end
  end
  # getting daynames from DAYNAME constant & rotating by 1 to get first day as Monday:
  day_name_arr = Date::DAYNAMES.rotate(1)
  # using each_with_object instead of reduce to do it in one line. Reduce would had required 
  # return of accumulator manually. Also observe that it requires opposite placement of 
  # |day, hash| as block arguments. It would haven been |hash, day| for reduce method.
  day_name_hash = day_name_arr.each_with_object({}) { |day, hash| hash[day_name_arr.index(day) + 1] = day }
  peak_day_index = days_hash.keys.select { |k| days_hash[k] == peak_day }
  peak_day_names = peak_day_index.map { |key| day_name_hash[key] } # day names array in words
  convert_arr_to_string(peak_day_names)
end

def convert_arr_to_string(arr_to_convert)
  arr_to_string = ''
  arr_to_convert.each_with_index do |ele, idx|
    # making a string of hours from array:
    arr_to_string += if idx == arr_to_convert.index(arr_to_convert[-1])
                       ele.to_s
                     else
                       # if its not last element, put comma after it:
                       "#{ele}, "
                     end
  end
  arr_to_string
end

puts "\nEvent Manager Initialized!"
puts

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hours_hash = Hash.new(0)
days_hash = Hash.new(0)
result_countdown = 0
# for waiting countdown. NOTE that it will be end of file after counting
result_countdown = contents.count
# To place cursor at start of file after above counting.
contents.rewind
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_num(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  time = Time.strptime(row[:regdate], '%m/%d/%y %k:%M')
  hours_hash[time.hour] += 1
  days_hash[time.wday] += 1
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  # puts "#{id} #{name} #{zipcode} #{phone_num} #{legislators}"
  puts "Countdown: #{result_countdown -= 1}"
end
peak_hours = find_peak_hours(hours_hash)
peak_days = find_peak_days(days_hash)

puts "\nPeak registration hour(s): #{peak_hours}"
puts "Peak registration day(s): #{peak_days}"
puts
