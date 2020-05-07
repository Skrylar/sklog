import sklog

#- A chimney is just a sequence of fluting.
var test_chimney: seq[LogFlute]

#- Here we add some fluting that rustles the jimmies of logs as they fall.
#- We could use some more meaningful value such as tacking a thread ID or
#- the current time.
test_chimney &= proc(values: var seq[LogKeyValues]) =
  values &= ("rustled", "jimmies")

#- And then we want it to go to stdout, in logfmt format.
test_chimney &= flute_to_logfmt_stdout

#- Now we drop a log through the chimney.
test_chimney.log({"diddly": "squat"})
