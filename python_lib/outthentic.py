import json
import glue

def config():

  json_file = glue.cache_dir() + "/config.json"
  with open(json_file) as data_file:
    data = json.load(data_file)
  return data


