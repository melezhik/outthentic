import json
from glue import *

def set_stdout(line):

  with open(stdout_file(), "a") as myfile:
    myfile.write(line)


if __name__ == "__main__":
  print 'ok'

