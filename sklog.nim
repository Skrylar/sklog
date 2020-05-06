
proc must_quote_for_logfmt*(input: string): bool =
  ## Checks whether the given string needs to be escaped to print on a logfmt
  ## line.
  discard # TODO

proc must_quote_for_json*(input: string): bool =
  ## Returns if a string needs any more work than just surrounding it in
  ## quotes, to echo it as part of a JSON document.
  discard # TODO

proc quote_for_logfmt*(input: string): string =
  ## Returns a new string which has been safely quoted to echo via logfmt.
  discard # TODO

proc quote_for_json*(input: string): string =
  ## Returns a new string which has been safely quoted to echo via JSON.
  discard # TODO

proc log*(values: openarray[(string, string)]) =
  ## Emits a key=value array to log output.
  var c = values.high
  for v in values:
    if must_quote_for_logfmt(v[0]):
      discard # TODO
    else:
      write stdout, v[0]

    write stdout, "="

    if must_quote_for_logfmt(v[1]):
      discard # TODO
    else:
      write stdout, v[1]

    if c > 0:
      write stdout, " "
      dec c

    flushFile stdout

log({"milk": "toast", "level": "info", "status": "ok"})
