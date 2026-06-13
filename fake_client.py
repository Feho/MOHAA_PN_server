#!/usr/bin/env python3
"""
Simulate a MOHAA client connection that stays in "preparing for deployment" state.

OpenMoHAA uses a Quake 3-derived protocol over UDP with adaptive Huffman
compression on connect packets. The connection handshake is:
  1. Client -> Server: getchallenge
  2. Server -> Client: challengeResponse <number>
  3. Client -> Server: connect "<userinfo>" (Huffman-compressed after "connect ")
  4. Server -> Client: connectResponse
  5. (Client never sends 'begin', so it stays in "preparing for deployment")
"""

import socket
import struct
import time
import argparse
import random


PLAYER_NAMES = [
    "Sgt.Miller", "Cpl.Dixon", "Pvt.Ryan", "Lt.Hawkins", "Maj.Burns",
    "Capt.Price", "Sgt.Foley", "Pvt.Allen", "Cpl.Dunn", "Lt.Vasquez",
    "Sgt.Reznov", "Pvt.Petrenko", "Cpl.Roebuck", "Sgt.Sullivan", "Pvt.Polonsky",
    "BlazeRunner", "ShadowStrike", "IronWolf", "StormRider", "NightHawk",
    "ThunderBolt", "FrostBite", "VenomX", "DarkKnight", "SteelNerve",
    "AceShooter", "GhostRecon", "ViperKing", "WarMachine", "DeadEye",
    "RapidFire", "ColdSteel", "BulletProof", "HellRaiser", "SkullCrush",
    "TacticalOps", "LoneWolf", "AlphaStrike", "BravoSix", "DeltaForce",
    "EchoTeam", "FoxTrot", "GolfUnit", "HotelNiner", "IndigoSquad",
    "JuliettCmd", "KiloActual", "LimaCharlie", "MikeForce", "NovaStar",
    "OscarMike", "PapaSmoke", "QuebecVic", "RomeoAlpha", "SierraOne",
    "TangoDown", "UniformSix", "VictorBravo", "WhiskeyRun", "XrayTeam",
    "YankeeGold", "ZuluWarrior", "Maverick", "Goose", "Iceman",
    "Viper", "Jester", "Merlin", "Slider", "Wolfman",
    "Mustang", "Cougar", "Sundown", "Hollywood", "Chipper",
    "D3STROY3R", "H34DSH0T", "N00BK1LL3R", "xX_Sniper_Xx", "L33TH4X",
    "CampMaster", "FragGod", "SpawnKill", "RushB", "ClutchKing",
    "OneTapWonder", "ScopeKing", "RunNGun", "FlankMaster", "PopSmoke",
    "BootCamp", "Rifleman", "Marksman", "Grenadier", "Medic",
    "Engineer", "Radioman", "Pointman", "Breacher", "Spotter",
    "Overlord", "Warhorse", "Raider", "Patriot", "Sentinel",
    "Nomad", "Spartan", "Viking", "Samurai", "Ronin",
]


# --- Adaptive Huffman compression (ported from OpenMoHAA huffman.cpp) ---

HMAX = 256
NYT = HMAX
INTERNAL_NODE = HMAX + 1


class Node:
    __slots__ = ("left", "right", "parent", "next", "prev", "head", "weight", "symbol")

    def __init__(self):
        self.left = None
        self.right = None
        self.parent = None
        self.next = None
        self.prev = None
        self.head = None  # index into head_ptrs list
        self.weight = 0
        self.symbol = 0


class HuffTree:
    """Adaptive Huffman tree for compression (port of huff_t from Q3)."""

    def __init__(self):
        self.node_list = [Node() for _ in range(768)]
        self.bloc_node = 0
        self.loc = [None] * (HMAX + 1)  # symbol -> leaf node
        self.head_ptrs = [None] * 768  # node pointer pool
        self.bloc_ptrs = 0
        self.free_list = []  # stack of free head_ptr indices
        self.tree = None
        self.lhead = None

        # Initialize with NYT node
        nyt = self.node_list[self.bloc_node]
        self.bloc_node += 1
        nyt.symbol = NYT
        nyt.weight = 0
        nyt.next = None
        nyt.prev = None
        nyt.parent = None
        nyt.left = None
        nyt.right = None
        nyt.head = self._get_ppnode()
        self.head_ptrs[nyt.head] = nyt
        self.tree = nyt
        self.lhead = nyt
        self.loc[NYT] = nyt

    def _get_ppnode(self):
        if self.free_list:
            return self.free_list.pop()
        idx = self.bloc_ptrs
        self.bloc_ptrs += 1
        return idx

    def _free_ppnode(self, idx):
        self.free_list.append(idx)

    def _swap(self, node1, node2):
        par1 = node1.parent
        par2 = node2.parent
        if par1:
            if par1.left is node1:
                par1.left = node2
            else:
                par1.right = node2
        else:
            self.tree = node2
        if par2:
            if par2.left is node2:
                par2.left = node1
            else:
                par2.right = node1
        else:
            self.tree = node1
        node1.parent = par2
        node2.parent = par1

    def _swaplist(self, node1, node2):
        par1 = node1.next
        node1.next = node2.next
        node2.next = par1
        par1 = node1.prev
        node1.prev = node2.prev
        node2.prev = par1
        if node1.next is node1:
            node1.next = node2
        if node2.next is node2:
            node2.next = node1
        if node1.next:
            node1.next.prev = node1
        if node2.next:
            node2.next.prev = node2
        if node1.prev:
            node1.prev.next = node1
        if node2.prev:
            node2.prev.next = node2

    def _increment(self, node):
        if node is None:
            return
        if node.next is not None and node.next.weight == node.weight:
            lnode = self.head_ptrs[node.head]
            if lnode is not node.parent:
                self._swap(lnode, node)
            self._swaplist(lnode, node)
        if node.prev and node.prev.weight == node.weight:
            self.head_ptrs[node.head] = node.prev
        else:
            self.head_ptrs[node.head] = None
            self._free_ppnode(node.head)
        node.weight += 1
        if node.next and node.next.weight == node.weight:
            node.head = node.next.head
        else:
            node.head = self._get_ppnode()
            self.head_ptrs[node.head] = node
        if node.parent:
            self._increment(node.parent)
            if node.prev is node.parent:
                self._swaplist(node, node.parent)
                if self.head_ptrs[node.head] is node:
                    self.head_ptrs[node.head] = node.parent

    def add_ref(self, ch):
        if self.loc[ch] is None:
            tnode = self.node_list[self.bloc_node]
            self.bloc_node += 1
            tnode2 = self.node_list[self.bloc_node]
            self.bloc_node += 1

            tnode2.symbol = INTERNAL_NODE
            tnode2.weight = 1
            tnode2.next = self.lhead.next
            if self.lhead.next:
                self.lhead.next.prev = tnode2
                if self.lhead.next.weight == 1:
                    tnode2.head = self.lhead.next.head
                else:
                    tnode2.head = self._get_ppnode()
                    self.head_ptrs[tnode2.head] = tnode2
            else:
                tnode2.head = self._get_ppnode()
                self.head_ptrs[tnode2.head] = tnode2
            self.lhead.next = tnode2
            tnode2.prev = self.lhead

            tnode.symbol = ch
            tnode.weight = 1
            tnode.next = self.lhead.next
            if self.lhead.next:
                self.lhead.next.prev = tnode
                if self.lhead.next.weight == 1:
                    tnode.head = self.lhead.next.head
                else:
                    tnode.head = self._get_ppnode()
                    self.head_ptrs[tnode.head] = tnode2
            else:
                tnode.head = self._get_ppnode()
                self.head_ptrs[tnode.head] = tnode
            self.lhead.next = tnode
            tnode.prev = self.lhead
            tnode.left = None
            tnode.right = None

            if self.lhead.parent:
                if self.lhead.parent.left is self.lhead:
                    self.lhead.parent.left = tnode2
                else:
                    self.lhead.parent.right = tnode2
            else:
                self.tree = tnode2

            tnode2.right = tnode
            tnode2.left = self.lhead
            tnode2.parent = self.lhead.parent
            self.lhead.parent = tnode2
            tnode.parent = tnode2

            self.loc[ch] = tnode
            self._increment(tnode2.parent)
        else:
            self._increment(self.loc[ch])


def huff_compress(data: bytes) -> bytes:
    """Compress data using Q3 adaptive Huffman. Returns compressed bytes."""
    size = len(data)
    if size <= 0:
        return data

    huff = HuffTree()
    out = bytearray(65536)
    # First 2 bytes: uncompressed size (big-endian)
    out[0] = (size >> 8) & 0xFF
    out[1] = size & 0xFF
    bloc = 16  # bit offset, starts after the 2-byte size header

    def add_bit(bit):
        nonlocal bloc
        byte_idx = bloc >> 3
        bit_idx = bloc & 7
        if bit_idx == 0:
            out[byte_idx] = 0
        if bit:
            out[byte_idx] |= 1 << bit_idx
        bloc += 1

    def send_node(node, child):
        """Recursively emit prefix code bits for a node."""
        if node.parent:
            send_node(node.parent, node)
        if child:
            if node.right is child:
                add_bit(1)
            else:
                add_bit(0)

    def transmit(ch):
        if huff.loc[ch] is None:
            # NYT: send NYT code, then raw 8-bit symbol
            transmit(NYT)
            for i in range(7, -1, -1):
                add_bit((ch >> i) & 1)
        else:
            send_node(huff.loc[ch], None)

    for byte_val in data:
        transmit(byte_val)
        huff.add_ref(byte_val)

    # Round up to next byte
    bloc += 8
    out_size = bloc >> 3
    return bytes(out[:out_size])


# --- OpenMoHAA network protocol ---

# Connectionless packet prefix + direction byte
OOB_PREFIX_SEND = b"\xff\xff\xff\xff\x02"
OOB_PREFIX_RECV = b"\xff\xff\xff\xff\x01"

PROTOCOL_VERSION = 8


def send_oob(sock, addr, data: str):
    """Send an out-of-band (connectionless) packet."""
    packet = OOB_PREFIX_SEND + data.encode("ascii")
    sock.sendto(packet, addr)


def send_oob_compressed(sock, addr, command: str, payload: str):
    """Send an OOB packet with Huffman-compressed payload.

    The server expects: [prefix][command ][huffman-compressed payload]
    For 'connect' packets, everything after 'connect ' (offset 13 from
    packet start = 5 prefix + 8 'connect ') is Huffman compressed.
    """
    header = OOB_PREFIX_SEND + command.encode("ascii") + b" "
    compressed = huff_compress(payload.encode("ascii"))
    sock.sendto(header + compressed, addr)


def recv_oob(sock, timeout=5.0):
    """Receive an out-of-band response. Returns the text after the prefix."""
    sock.settimeout(timeout)
    try:
        data, addr = sock.recvfrom(4096)
        if data[:5] == OOB_PREFIX_RECV:
            return data[5:].decode("ascii", errors="replace"), addr
        if data[:4] == b"\xff\xff\xff\xff":
            return data[4:].decode("ascii", errors="replace"), addr
        return data.decode("ascii", errors="replace"), addr
    except socket.timeout:
        return None, None


def build_userinfo(name="PyBot", rate=25000, qport=0, challenge="0"):
    """Build a MOHAA-style userinfo string: \\key\\value\\key\\value"""
    pairs = [
        ("protocol", str(PROTOCOL_VERSION)),
        ("challenge", str(challenge)),
        ("qport", str(qport)),
        ("name", name),
        ("rate", str(rate)),
        ("snaps", "20"),
        ("dm_playermodel", "american_army"),
        ("dm_playergermanmodel", "german_wehrmacht_soldier"),
    ]
    return "".join(f"\\{k}\\{v}" for k, v in pairs)


def connect_fake_client(host, port, name="PyBot", hold_time=60):
    """
    Perform the MOHAA connection handshake and hold in "preparing for deployment".

    The client completes steps 1-4 of the handshake but never sends 'begin',
    so the server shows the player as "preparing for deployment".
    """
    addr = (host, port)
    qport = random.randint(1024, 65535)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("", 0))

    print(f"[*] Connecting to {host}:{port} as '{name}'...")

    # Step 1: getchallenge
    send_oob(sock, addr, "getchallenge")
    print("[>] Sent getchallenge")

    response, _ = recv_oob(sock)
    if response is None:
        print("[!] No response to getchallenge. Server might be down or unreachable.")
        sock.close()
        return

    print(f"[<] {response.strip()}")

    # Parse challenge number
    if "challengeResponse" not in response:
        print(f"[!] Unexpected response: {response}")
        sock.close()
        return

    parts = response.strip().split()
    challenge_idx = parts.index("challengeResponse") + 1
    challenge = parts[challenge_idx]
    print(f"[*] Got challenge: {challenge}")

    # Step 2: connect (with Huffman-compressed payload)
    userinfo = build_userinfo(name, rate=25000, qport=qport, challenge=challenge)

    # The server Huffman-decompresses everything after "connect " (offset 13).
    # The quoted userinfo string is the compressed payload.
    payload = f'"{userinfo}"'
    send_oob_compressed(sock, addr, "connect", payload)
    print("[>] Sent connect (Huffman-compressed)")

    response, _ = recv_oob(sock)
    if response is None:
        print("[!] No response to connect. Server may have rejected the connection.")
        sock.close()
        return

    print(f"[<] {response.strip()}")

    if "connectResponse" not in response and "onnectResponse" not in response:
        print(f"[!] Connection rejected: {response}")
        sock.close()
        return

    print(f"[*] '{name}' is now in 'preparing for deployment' state!")
    print(f"[*] Holding connection for {hold_time} seconds (Ctrl+C to disconnect)...")

    # Stay alive by sending periodic nop/heartbeat packets
    # The server expects some traffic or it will time out the client (sv_timeout)
    try:
        start = time.time()
        while time.time() - start < hold_time:
            # Send a nop-like packet to keep the connection alive
            # In Q3 protocol, the client sends sequenced packets;
            # we send a minimal game packet with just the sequence number
            seq = int(time.time() - start) & 0xFFFFFFFF
            keepalive = struct.pack("<I", seq) + b"\x00"
            sock.sendto(keepalive, addr)
            time.sleep(2)
    except KeyboardInterrupt:
        print("\n[*] Interrupted by user.")

    print(f"[*] Disconnecting '{name}'...")
    # Send disconnect
    send_oob(sock, addr, "disconnect")
    sock.close()
    print("[*] Done.")


def main():
    parser = argparse.ArgumentParser(
        description="Simulate a MOHAA client stuck in 'preparing for deployment'"
    )
    parser.add_argument("host", nargs="?", default="127.0.0.1", help="Server IP (default: 127.0.0.1)")
    parser.add_argument("port", nargs="?", type=int, default=12203, help="Server port (default: 12203)")
    parser.add_argument("-n", "--name", default="PyBot", help="Player name (default: PyBot)")
    parser.add_argument("-t", "--time", type=int, default=120, help="Seconds to hold connection (default: 120)")
    parser.add_argument("-c", "--count", type=int, default=1, help="Number of fake clients to connect")
    parser.add_argument("-l", "--loop", action="store_true", help="Repeat every 15-20 minutes")

    args = parser.parse_args()

    def pick_name():
        return random.choice(PLAYER_NAMES)

    def run_once():
        if args.count == 1:
            connect_fake_client(args.host, args.port, pick_name(), args.time)
        else:
            import threading

            threads = []
            for i in range(args.count):
                t = threading.Thread(
                    target=connect_fake_client,
                    args=(args.host, args.port, pick_name(), args.time),
                )
                threads.append(t)
                t.start()
                time.sleep(0.5)

            for t in threads:
                t.join()

    if args.loop:
        print("[*] Loop mode: will repeat every 15-20 minutes. Ctrl+C to stop.")
        while True:
            try:
                run_once()
                delay = random.randint(15 * 60, 20 * 60)
                print(f"[*] Next connection in {delay // 60}m {delay % 60}s...")
                time.sleep(delay)
            except KeyboardInterrupt:
                print("\n[*] Loop stopped.")
                break
    else:
        run_once()


if __name__ == "__main__":
    main()
