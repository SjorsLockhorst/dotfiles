#!/usr/bin/env python3
"""QEMU helpers for test/vm/run.sh (standard library only)."""
import argparse
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


class Console:
    """The serial console: one client at a time, output from when it connects."""

    def __init__(self, path):
        self.s = connect(path, 30)
        self.s.settimeout(1)
        self.seen = ""

    def wait(self, pattern, timeout):
        deadline = time.monotonic() + timeout
        while not re.search(pattern, self.seen):
            if time.monotonic() > deadline:
                sys.exit(f"serial: no {pattern!r} within {timeout}s")
            try:
                chunk = self.s.recv(4096)
            except TimeoutError:
                continue
            if not chunk:
                sys.exit("serial: the console closed")
            self.seen = (self.seen + chunk.decode("latin-1"))[-4096:]
        self.seen = ""

    def type(self, text):
        # One key at a time: the emulated UART's 16-byte FIFO drops a fast burst.
        for c in text + "\r":
            self.s.sendall(c.encode())
            time.sleep(0.05)


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


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    q = sub.add_parser("qmp", help="run a QMP command")
    q.add_argument("socket")
    q.add_argument("command")
    q.add_argument("arguments", nargs="?", help="JSON object")
    s = sub.add_parser("screenshot", help="save the screen as PNG")
    s.add_argument("socket", help="QMP socket")
    s.add_argument("file")
    t = sub.add_parser("type", help="wait for a prompt on the serial console, type an answer")
    t.add_argument("socket", help="serial socket")
    t.add_argument("--wait", required=True, help="regex of the prompt")
    t.add_argument("--text", required=True)
    t.add_argument("--then", help="regex to wait for after typing")
    t.add_argument("--timeout", type=int, default=120)
    sub.add_parser("dns", help="the first nameserver in /etc/resolv.conf that answers: "
                   "QEMU's DNS forwarder only tries the first one, which may be down")
    a = p.parse_args()

    if a.cmd == "qmp":
        qmp(a.socket, a.command, json.loads(a.arguments) if a.arguments else None)
    elif a.cmd == "screenshot":
        qmp(a.socket, "screendump", {"filename": a.file, "format": "png"})
    elif a.cmd == "type":
        console = Console(a.socket)
        console.wait(a.wait, a.timeout)
        console.type(a.text)
        if a.then:
            console.wait(a.then, a.timeout)
    elif a.cmd == "dns":
        print(working_nameserver())


if __name__ == "__main__":
    main()
