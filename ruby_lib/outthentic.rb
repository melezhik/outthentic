require 'glue'

def set_stdout line
  open(stdout_file(), 'a') do |f|
    f.puts "#{line}\n"
  end
end


def run_story path

    if debug_mod12
        puts "# run downstream story: #{path}"
    end

    puts "story: #{path}"

end


def ignore_story_err val
  puts "ignore_story_err: #{val}"
end

