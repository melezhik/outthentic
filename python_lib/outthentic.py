from glue import *
import json

def set_stdout(line):

  with open(stdout_file(), "a") as myfile:
    myfile.write(line)

def config():

  json_file = cache_dir() + "/config.json"

  with open(json_file) as data_file:
    data = json.load(data_file)

  return data


def run_story(path, params):

    if debug_mod12():
      print "# run downstream story: " + path

    print "story_var_json_begin"
    print json.dumps(params, ensure_ascii=False)
    print "story_var_json_end"
    print "story: " + path

