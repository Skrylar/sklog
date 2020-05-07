#- = Structured logging

type
    #- This is a string-string tuple because the syntax `{"foo": "bar"}`
    #- is a table constructor that produces arrays of string-string tuples.
    LogKeyValues* = (string, string)
    #- A flute ("fluting") will modify or emit values on their way through
    #- the chimney. This can be used to mark which script interpreter is
    #- making the log events, or which thread is doing so during fork-joins.
    LogFlute* = proc(variables: var seq[LogKeyValues]) {.closure.}
    #- A chimney is an ordered sequence of flutes.
    LogChimney* = seq[LogFlute]

#- == Checking if input needs special quotation

proc must_quote_for_logfmt*(input: string): bool =
  ## Checks whether the given string needs to be escaped to print on a logfmt
  ## line.
  for ch in input:
    case ch:
    of 'a'..'z', 'A'..'Z', '0'..'9', '-', '_':
      continue
    else:
      return true
  return false

proc must_quote_for_json*(input: string): bool =
  ## Returns if a string needs any more work than just surrounding it in
  ## quotes, to echo it as part of a JSON document.
  discard # TODO

#- == Applying special quotations

proc quote_for_logfmt*(input: string): string =
  ## Returns a new string which has been safely quoted to echo via logfmt.
  result = newStringOfCap(input.len)

  result &= "\""
  for ch in input:
    case ch:
    of '"', '\\':
      result &= '\\'
      result &= ch
    else:
      result &= ch
  result &= "\""

proc quote_for_json*(input: string): string =
  ## Returns a new string which has been safely quoted to echo via JSON.
  discard # TODO

#- == Mixin: write key/values to stdout
#- Used because writing to stdout is the same, whether we do it from the
#- quick no-copy `log` call or the slower copying `log` call.
template dump_the_vars(values: untyped) =
  var c = values.high
  for v in values:
    if must_quote_for_logfmt(v[0]):
      write stdout, quote_for_logfmt(v[0])
    else:
      write stdout, v[0]

    write stdout, "="

    if must_quote_for_logfmt(v[1]):
      write stdout, quote_for_logfmt(v[1])
    else:
      write stdout, v[1]

    if c > 0:
      write stdout, " "
      dec c

  write stdout, "\n"
  flushFile stdout

#- == Logging without chimneys
#- This is *very* efficient since it directly writes the values to stdout
#- and does no copying. Useful for processes too small to bother with
#- more complicated logging.
proc log*(values: openarray[LogKeyValues]) =
  ## Emits a key=value array to log output; bypasses any fluting.
  dump_the_vars(values)

#- == Logging through chimneys
#- A chimney is a sequence of procedures which may modify the values on the
#- way down. The contents are said to become "sooty" as they fall down the
#- chimney and are mutated. You should make sure one or more procs actually
#- send the log to a console, socket or another thread when they are done
#- tumbling or else this whole activity is pointless.

proc log*(flute: LogChimney; values: openarray[LogKeyValues]) =
  ## Sends some variables "down the chimney." A copy of the sequence is made
  ## so it does not get sooty on the way down.

  # copy values to a mutable sequence
  var x: seq[LogKeyValues]
  newSeq(x, values.len)
  for i in 0..values.high:
    x[i] = values[i]

  # now send them down the chimney
  for f in flute:
    f(x)

#- === Quick logging, with disposable data
#- Quick logging assumes you have a mutable sequence,
#- perhaps because you have been building a
#- https://www.brandur.org/canonical-log-lines[canonical log line]. It also
#- assumes you are sacrificing the sequence to the chimney.
#-
#- What makes this "quick" is that the non-quick `log` routine makes a
#- copy of its input.
proc qlog*(flute: LogChimney; values: var seq[LogKeyValues]) =
  ## Send values down the chimney. The value sequence you provide is gonna
  ## get mangled by soot on the way down.
  for f in flute:
    f(values)

#- === Sending values to stdout via the chimney
proc flute_to_logfmt_stdout*(values: var seq[LogKeyValues]) =
  ## Writes the incoming set of values in logfmt, to standard output.
  dump_the_vars(values)

