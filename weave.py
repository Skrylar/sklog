import sys

lines = []
with open(sys.argv[1], "r") as f:
    lines = f.readlines()

# find out which mode we start in
in_code = None
if lines[0].strip().startswith("#- ") or lines[0].strip() == '#-':
    in_code = False
else:
    in_code = True

if in_code:
    print("[source,nim]\n----")

# ok now go
for line in lines:
    clork = line.strip()
    if clork.startswith("#- ") or clork == '#-':
        if in_code:
            # transition to literate mode
            in_code = False
            print("----")
            print(clork[3:])
        else:
            print(clork[3:])
    else:
        if in_code:
            sys.stdout.write(line)
        else:
            # transition to code mode
            print("\n[source,nim]\n----")
            sys.stdout.write(line)
            in_code = True

if in_code:
    print("\n----")
