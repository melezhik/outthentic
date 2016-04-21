require 'glue'

def set_stdout line
  open(stdout_file(), 'a') do |f|
    f.puts "#{line}\n"
  end
end


def run_story path


    test_file = "#{test_root_dir}/#{project_root_dir}/modules/#{path}/story.d"

    raise "test file: #{test_file} does not exist" unless File.exist? test_file;

    if debug_mod12
        puts "# run downstream story: #{path}"
    end

    puts `perl #{test_file}`


end




