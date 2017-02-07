from glue import *
import json

STORY_VARIABLES = None
CONFIG = None

def set_stdout(line):
  with open(stdout_file(), "a") as myfile:
    myfile.write(line)
  
def config():

  global CONFIG

  if CONFIG:
    return CONFIG
  else:
    json_file = cache_dir() + "/config.json"
    with open(json_file) as data_file:
      CONFIG = json.load(data_file)
    return CONFIG
  

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


def story_variables():

  global STORY_VARIABLES

  if STORY_VARIABLES:
    return STORY_VARIABLES
  else:
    json_file = cache_dir() + "/variables.json"
  
    with open(json_file) as data_file:
      STORY_VARIABLES = json.load(data_file)
  
    return STORY_VARIABLES
  

def story_var(name):

  return story_variables()[name]

