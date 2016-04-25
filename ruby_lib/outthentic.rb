require 'glue'
require 'json'

def set_stdout line
  open(stdout_file(), 'a') do |f|
    f.puts "#{line}\n"
  end
end


def run_story path, params = {}

    if debug_mod12
        puts "# run downstream story: #{path}"
    end

    puts "story_vars:"
    puts params.to_json
    puts "story_vars:"
    puts "story: #{path}"

end


def ignore_story_err val
  puts "ignore_story_err: #{val}"
end

def captures
   @captures ||= JSON.parse(File.read("#{cache_dir}/captures.json"))  
end

def capture
    captures.first
end

def story_variables 
   @module_varaibles ||= JSON.parse(File.read("#{cache_dir}/variables.json"))  
end

def story_variable name
  story_variables[name]
end

