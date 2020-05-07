
import sklog

#- The `log` function, given only a set of key/values will print directly to
#- standard output.
log({"milk": "unquoted", "level": "info", "status": "ok"})
#- This is done in logfmt so you will see `milk=unquoted`.

#- If a value contains anything too weird (alphanumerics, dashes and underlines
#- are okay) then the string will be quoted.
log({"milk": "toast is good", "level": "info", "status": "ok"})
#- This time, `milk` is printed as `milk="toast is good"`.
