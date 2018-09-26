
require 'glue'
require 'json'

if File.exist? "#{story_dir}/common.rb"

  require "#{story_dir}/common.rb"

end

if File.exist? "#{project_root_dir}/common.rb"

  require "#{project_root_dir}/common.rb"

end

def set_stdout line
  open(stdout_file(), 'a') do |f|
    f.puts "#{line}\n"
  end
end


def run_story path, params = {}

    if debug_mod12
        puts "# run downstream story: #{path}"
    end

    puts "story_var_json_begin"
    puts params.to_json
    puts "story_var_json_end"
    puts "story: #{path}"

end


def ignore_story_err val
  puts "ignore_story_err: #{val}"
end

def quit msg
  puts "quit: #{msg}"
  exit
end

def outthentic_die msg
  puts "outthentic_die: #{msg}"
  exit
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

def story_var name
  story_variables[name]
end

def config
   @config ||= JSON.parse(File.read("#{cache_dir}/config.json"))  
end

