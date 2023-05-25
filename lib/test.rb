require 'time'

time = Time.strptime('11/12/2008 10:47', '%d/%m/%Y %k:%M').wday
days_hash = { 3 => 7, 2 => 1, 1 => 7, 4 => 5, 0 => 4 }
peak_day = days_hash.reduce(0) do |acc, (k, v)|
  
  if acc > v
    acc
    else
      v
  end

end
day_name_arr = Date::DAYNAMES.rotate(1)
day_name_hash = Date::DAYNAMES.rotate(1).each_with_object({}) { |day, hash| hash[day_name_arr.index(day) + 1] = day }

peak_day_index = days_hash.keys.select { |k| days_hash[k] == peak_day }
peak_day_name = peak_day_index.map { |key| day_name_hash[key] }
p peak_day_name

# hash = Hash
