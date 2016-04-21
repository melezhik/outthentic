require 'glue'

def set_stdout line
  open(stdout_file(), 'a') do |f|
    f.puts "#{line}\n"
  end
end





