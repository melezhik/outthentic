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


def run_story( path, params = [] ):

    print "story_var_json_begin"
    if bool(params):
      print json.dumps(params, ensure_ascii=False)
    else:
      print "{}"

    print "story_var_json_end"
    print "story: " + path


def ignore_story_err(val):
  print "ignore_story_err: " + str(val)

