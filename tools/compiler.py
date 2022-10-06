#!/usr/bin/env python3

# The Compiler, see ASM.README

import argparse
import re

DEFAULT_OUT = "a.acom16"

class Cmd(object):
    def __init__(self, name, regnum, inum):
        self.name = name
        self.regnum = regnum
        self.inum = inum

class Translator(object):
    def __init__(self, infile):
        self.infile = infile
        self.symbols = {}
        self.binout = []
        self.CMDS = [
            Cmd("ADD", 3, 0),
            Cmd("ADDI", 2, 1),
            Cmd("NAND", 3, 0),
            Cmd("LUI", 1, 1),
            Cmd("SW", 2, 1),
            Cmd("LW", 2, 1),
            Cmd("BEQ", 2, 1),
            Cmd("JMP", 2, 0)
        ]
        self.NUMREG = 8

    def syms(self):
        data = False
        text = False
        address = 4
        idrgx = re.compile('^[_a-zA-Z][_a-zA-Z0-9]*$')
        rgrgx = re.compile('^R[0-7]$')
        for line in self.infile:
            tmp = line.split('#', 1)[0]
            tmp = tmp.split()
            if not tmp:
                continue
            if len(tmp) == 1:
                if not (text or data) and (tmp[0] == ".DATA"):
                    data = True
                    continue
                if not text and (tmp[0] == ".TEXT"):
                    data = False
                    text = True
                    continue
                if not (text or data):
                    raise Exception("Malformed input")
            if tmp[0][-1] == ':':
                lname = tmp[0][:-1]
                if not idrgx.match(lname):
                    raise Exception("Invalid label")
                if lname in self.symbols.keys():
                    raise Exception("Duplicate label")
                self.symbols[lname] = address + 2
                tmp = tmp[1:]
            if not tmp:
                continue
            if data:
                for v in tmp:
                    iv = int(v)
                    if (iv > 65535) or (iv < -32768):
                        raise Exception("Data out of range")
                    self.binout.append(iv)
                    address += 2
                continue
            if text:
                cc = None
                for c in self.CMDS:
                    if c.name == tmp[0]:
                        cc = c
                        break
                if not cc:
                    raise Exception("Unknown command", tmp[0])
                if len(tmp) != (1 + cc.regnum + cc.inum):
                    raise Exception("Malformed command", tmp)
                for i, v in enumerate(tmp):
                    if (i > 0) and (i <= cc.regnum):
                        if not rgrgx.match(v):
                            raise Exception("Wrong register name", tmp, v)
                # we do not check immediate here, as it can be future label
                # this check will be performed on translation
                address += 2
        return

    def translate(self):
        self.binout.append(0) # ADDI PLACEHOLDER
        self.binout.append(0) # JMP  PLACEHOLDER
        self.syms()
        if "START" not in self.symbols.keys():
            raise Exception("No START label")

    def dump(self, outfile):
        return

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("infile", help="assembly file")
    parser.add_argument("-o", "--out", help="Output binary")
    args = parser.parse_args()

    infile = args.infile
    outfile = args.out or DEFAULT_OUT

    with open(infile, 'r') as f:
        t = Translator(f)
        t.translate()
        t.dump(outfile)
