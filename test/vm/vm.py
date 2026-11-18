#!/usr/bin/env python3
"""QEMU helpers for test/vm/run.sh (standard library only).

  vm.py qmp <socket> <command> [<json arguments>]
      run a QMP command, e.g. screendump '{"filename": "x.png", "format": "png"}'
  vm.py type <serial socket> <regex> <text> [<timeout seconds>]
      wait until the serial console prints <regex>, then type <text> and Enter
  vm.py dns
      print the first nameserver in /etc/resolv.conf that answers (QEMU's own
      DNS forwarder only tries the first one, which may be down)
"""
import json
import random
import re
import socket
import struct
import sys
import time


def connect(path, timeout):
    deadline = time.monotonic() + timeout
    while True:
        s = socket.socket(socket.AF_UNIX)
        try:
            s.connect(path)
            return s
        except (FileNotFoundError, ConnectionRefusedError):
            s.close()
            if time.monotonic() > deadline:
                raise
            time.sleep(0.2)


def qmp(path, command, arguments=None):
    f = connect(path, 10).makefile("rw")
    json.loads(f.readline())  # greeting
    request = {"execute": command}
    if arguments:
        request["arguments"] = arguments
    for message in ({"execute": "qmp_capabilities"}, request):
        f.write(json.dumps(message) + "\n")
        f.flush()
        while True:
            reply = json.loads(f.readline())
            if "event" not in reply:
                break
        if "error" in reply:
            sys.exit(f"qmp {command}: {reply['error']['desc']}")


def type_after(path, pattern, text, timeout):
    s = connect(path, 30)
    s.settimeout(1)
    seen = ""
    deadline = time.monotonic() + timeout
    while not re.search(pattern, seen):
        if time.monotonic() > deadline:
            sys.exit(f"serial: no {pattern!r} within {timeout}s")
        try:
            chunk = s.recv(4096)
        except TimeoutError:
            continue
        if not chunk:
            sys.exit("serial: the console closed")
        seen = (seen + chunk.decode("latin-1"))[-4096:]
    # One key at a time: the emulated UART's 16-byte FIFO drops a fast burst.
    for c in text + "\r":
        s.sendall(c.encode())
        time.sleep(0.05)
    s.close()


def answers(server, name="archlinux.org"):
    query = struct.pack(">HHHHHH", random.randrange(65536), 0x0100, 1, 0, 0, 0)
    query += b"".join(bytes([len(p)]) + p.encode() for p in name.split(".")) + b"\0"
    query += struct.pack(">HH", 1, 1)  # A, IN
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    try:
        s.sendto(query, (server, 53))
        return len(s.recv(512)) > 12
    except OSError:
        return False
    finally:
        s.close()


def working_nameserver():
    with open("/etc/resolv.conf") as f:
        servers = [line.split()[1] for line in f if line.startswith("nameserver")]
    # A loopback resolver (127.0.0.53) isn't reachable from the VM
    for server in servers:
        if ":" not in server and not server.startswith("127.") and answers(server):
            return server
    sys.exit(f"no nameserver in /etc/resolv.conf answers (tried {servers})")


if __name__ == "__main__":
    if sys.argv[1:] == ["dns"]:
        print(working_nameserver())
    elif len(sys.argv) >= 4 and sys.argv[1] == "qmp":
        qmp(sys.argv[2], sys.argv[3], json.loads(sys.argv[4]) if len(sys.argv) > 4 else None)
    elif len(sys.argv) in (5, 6) and sys.argv[1] == "type":
        type_after(sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]) if len(sys.argv) > 5 else 120)
    else:
        sys.exit(__doc__)
