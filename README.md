`sklog` is a lightweight structured logging module. It is primarily
based around
[logfmt](https://rollout.io/blog/logfmt-a-log-format-thats-easy-to-read-and-write/)
for its ease of machine emission and parsing. It also prefers to log to
stdout as in [Twelve-Factor Apps](https://12factor.net/).

Some nice to haves (that are not here \[yet?\]):

  - Explicit multi-threading support,

  - Tracing (think Hawktracer, Tracy),

# License

  - MPL-2. (Mozilla Public License, v2)

# Dependencies

  - This module is currently standalone.

# How the docs are built

`sklog` is written with a literate approach. Special lines starting with
`#-` indicate some Asciidoc prose occurs on the line. All other lines
are code as per usual.

There is no `tangle` phase; source files are built directly with Nim.
The `weave` phase is handled by `weave.py` and "flips" comment lines to
prose and code lines to source code blocks.

In this case `readme-base.adoc` is some front matter for the repository,
and glue instructions to have the examples and documentation included.
We then use [Asciidoctor.rb](https://asciidoctor.org/) to turn the front
matter to Docbook and finally [Pandoc](https://pandoc.org/) to turn the
Docbook in to Git Flavored Markdown for Sourcehut and Github.

# Other things

If you need a lot of shiny bells and whistles you might be better served
by [Chronicles](https://github.com/status-im/nim-chronicles). They have
done a fine job.

# Examples

## Simple usage example

``` nim
import sklog
```

The `log` function, given only a set of key/values will print directly
to standard output.

``` nim
log({"milk": "unquoted", "level": "info", "status": "ok"})
```

This is done in logfmt so you will see `milk=unquoted`.

If a value contains anything too weird (alphanumerics, dashes and
underlines are okay) then the string will be quoted.

``` nim
log({"milk": "toast is good", "level": "info", "status": "ok"})
```

This time, `milk` is printed as `milk="toast is good"`.

## Introduction to Fluting and Chimneys

``` nim
import sklog
```

A chimney is just a sequence of fluting.

``` nim
var test_chimney: seq[LogFlute]
```

Here we add some fluting that rustles the jimmies of logs as they fall.
We could use some more meaningful value such as tacking a thread ID or
the current time.

``` nim
test_chimney &= proc(values: var seq[LogKeyValues]) =
  values &= ("rustled", "jimmies")
```

And then we want it to go to stdout, in logfmt format.

``` nim
test_chimney &= flute_to_logfmt_stdout
```

Now we drop a log through the chimney.

``` nim
test_chimney.log({"diddly": "squat"})
```

# The module

## Structured logging

``` nim
type
```

This is a string-string tuple because the syntax `{"foo": "bar"}` is a
table constructor that produces arrays of string-string tuples.

``` nim
    LogKeyValues* = (string, string)
```

A flute ("fluting") will modify or emit values on their way through the
chimney. This can be used to mark which script interpreter is making the
log events, or which thread is doing so during fork-joins.

``` nim
    LogFlute* = proc(variables: var seq[LogKeyValues]) {.closure.}
```

A chimney is an ordered sequence of flutes.

``` nim
    LogChimney* = seq[LogFlute]
```

### Checking if input needs special quotation

``` nim
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
```

### Applying special quotations

``` nim
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
```

### Mixin: write key/values to stdout

Used because writing to stdout is the same, whether we do it from the
quick no-copy `log` call or the slower copying `log` call.

``` nim
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
```

### Logging without chimneys

This is **very** efficient since it directly writes the values to stdout
and does no copying. Useful for processes too small to bother with more
complicated logging.

``` nim
proc log*(values: openarray[LogKeyValues]) =
  ## Emits a key=value array to log output; bypasses any fluting.
  dump_the_vars(values)
```

### Logging through chimneys

A chimney is a sequence of procedures which may modify the values on the
way down. The contents are said to become "sooty" as they fall down the
chimney and are mutated. You should make sure one or more procs actually
send the log to a console, socket or another thread when they are done
tumbling or else this whole activity is pointless.

``` nim
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
```

#### Quick logging, with disposable data

Quick logging assumes you have a mutable sequence, perhaps because you
have been building a [canonical log
line](https://www.brandur.org/canonical-log-lines). It also assumes you
are sacrificing the sequence to the chimney.

What makes this "quick" is that the non-quick `log` routine makes a copy
of its input.

``` nim
proc qlog*(flute: LogChimney; values: var seq[LogKeyValues]) =
  ## Send values down the chimney. The value sequence you provide is gonna
  ## get mangled by soot on the way down.
  for f in flute:
    f(values)
```

#### Sending values to stdout via the chimney

``` nim
proc flute_to_logfmt_stdout*(values: var seq[LogKeyValues]) =
  ## Writes the incoming set of values in logfmt, to standard output.
  dump_the_vars(values)
```
