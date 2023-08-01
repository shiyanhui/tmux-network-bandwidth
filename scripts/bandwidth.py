import subprocess

result = subprocess.run(
  ["netstat", "-ibn"],
  stdout=subprocess.PIPE,
  stderr=subprocess.PIPE
)

bytesReceived, bytesSent, seen = 0, 0, set()
for item in result.stdout.decode("utf-8").split("\n")[1:]:
  parts = list(filter(lambda x: x, item.split(" ")))
  if not parts:
    continue

  name, ibytes, obytes = parts[0], parts[-5], parts[-2]
  if not name.startswith("en") or name in seen:
    continue
  seen.add(name)

  bytesReceived += int(ibytes)
  bytesSent += int(obytes)

print(bytesReceived, bytesSent)
