#!/usr/bin/env python3

# The Compiler, see ASM.README

import argparse
import re

DEFAULT_OUT = "a.acom16"

class Cmd(object):
    def __init__(self, regnum, inum, isize):
        self.regnum = regnum
        self.inum = inum
        self.isize = isize

class Translator(object):
    def __init__(self, infile):
        self.infile = infile
        self.symbols = {}
        self.binout = []
        self.asm = []
        self.CMDS = {
            "ADD" : Cmd(3, 0, 0),
            "ADDI" : Cmd(2, 1, 7),
            "NAND" : Cmd(3, 0, 0),
            "LUI" : Cmd(1, 1, 10),
            "SW" : Cmd(2, 1, 7),
            "LW" : Cmd(2, 1, 7),
            "BEQ" : Cmd(2, 1, 7),
            "JALR" : Cmd(2, 0, 0)
        }
        self.NUMREG = 8

    def syms(self):
        data = False
        text = False
        address = 3
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
                self.symbols[lname] = address
                tmp = tmp[1:]
            if not tmp:
                continue
            if data:
                for v in tmp:
                    iv = int(v)
                    if (iv > 65535) or (iv < -32768):
                        raise Exception("Data out of range")
                    self.binout.append(iv)
                    self.asm.append("DATA {}".format(iv))
                    address += 1
                continue
            if text:
                if tmp[0] not in self.CMDS.keys():
                    raise Exception("Unknown command", tmp[0])
                cc = self.CMDS[tmp[0]]
                if len(tmp) != (1 + cc.regnum + cc.inum):
                    raise Exception("Malformed command", tmp)
                for i, v in enumerate(tmp):
                    if (i > 0) and (i <= cc.regnum):
                        if not rgrgx.match(v):
                            raise Exception("Wrong register name", tmp, v)
                # we do not check immediate here, as it can be future label
                # this check will be performed on translation
                address += 1
        return

    def translate(self):
        idrgx = re.compile('^[_a-zA-Z][_a-zA-Z0-9]*$')
        self.binout.append(0) # LUI PLACEHOLDER
        self.binout.append(0) # ADDI PLACEHOLDER
        self.binout.append(0) # JALR PLACEHOLDER
        self.asm.append("")
        self.asm.append("")
        self.asm.append("")
        self.syms()
        if "START" not in self.symbols.keys():
            raise Exception("No START label")
        start = self.symbols["START"]
        h = (start & 0xFFC0) >> 6
        l = start & 0x003F
        # LUI R1 h
        # ADDI R1 R1 l
        # JALR R0 R1
        self.binout[0] = (3 << 13) | (1 << 10) | h
        self.binout[1] = (1 << 13) | (1 << 10) | (1 << 7) | l
        self.binout[2] = (7 << 13) | (0 << 10) | (1 << 7)
        self.asm[0] = "{} {} {}".format("LUI", "R1", h)
        self.asm[1] = "{} {} {} {}".format("ADDI", "R1", "R1", l)
        self.asm[2] = "{} {} {}".format("JALR", "R0", "R1")
        text = False
        self.infile.seek(0, 0)
        for line in self.infile:
            tmp = line.split('#', 1)[0]
            tmp = tmp.split()
            if not tmp:
                continue
            if not text and (tmp[0] == ".TEXT"):
                text = True
                continue
            if not text:
                continue
            if tmp[0][-1] == ':':
                tmp = tmp[1:]
            if not tmp:
                continue
            cmd = list(self.CMDS.keys()).index(tmp[0]) << 13
            discmd = tmp[0]
            for i in range(self.CMDS[tmp[0]].regnum):
                shift = (i != 2) and (10 - (i * 3)) or 0
                cmd = cmd | (int(tmp[i + 1][1:]) << shift)
                discmd = "{} {}".format(discmd, tmp[i + 1])
            for i in range(self.CMDS[tmp[0]].inum):
                imm = tmp[i + self.CMDS[tmp[0]].regnum + 1]
                # imm can be a label or numeric
                # if label, get address: if size 10 : 10 MSB
                #                        if size  7 :  6 LSB
                # if BEQ, calculate the jump
                # convert to numeric, check the range
                #                        if size 10 :   0 1023
                #                        if size  7 : -64 63
                if idrgx.match(imm):
                    # label
                    if imm not in self.symbols.keys():
                        raise Exception("Invalid immediate")
                    imm = self.symbols[imm]
                    if tmp[0] == 'BEQ':
                        cur = len(self.binout)
                        imm = imm - (cur + 1)
                        if ((imm < -64) or (imm > 63)):
                            raise Exception("Jump is loo long")
                    else:
                        if (self.CMDS[tmp[0]].isize == 10):
                            imm = (imm & 0xFFC0) >> 6
                        if (self.CMDS[tmp[0]].isize == 7):
                            imm = imm & 0x003F
                else:
                    imm = int(imm)
                    if (self.CMDS[tmp[0]].isize == 7) and ((imm < -64) or (imm > 63)):
                        raise Exception("Immediate is out of range")
                    if (self.CMDS[tmp[0]].isize == 10) and ((imm < 0) or (imm > 1023)):
                        raise Exception("Immediate is out of range")
                discmd = "{} {}".format(discmd, imm)
                if imm < 0:
                    imm = - imm
                    imm = imm | 64
                cmd = cmd | imm
            self.binout.append(cmd)
            self.asm.append(discmd)

    def dump(self):
        print("SYMBOLS TABLE:")
        for k, v in self.symbols.items():
            print("{0:04x}: {1}".format(v, k))
        print()
        print("BINARY:")
        for i, v in enumerate(self.binout):
            print("{0:04x}: {1:016b}    | {2}".format(i, v, self.asm[i]))

    def wout(self, outfile):
        with open(outfile, 'wb') as o:
            for v in self.binout:
                b = v.to_bytes(2, 'big')
                o.write(b)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("infile", help="Assembly file")
    parser.add_argument("-o", "--out", help="Output binary")
    parser.add_argument("-d", "--dump", action="store_true")
    args = parser.parse_args()

    infile = args.infile
    outfile = args.out or DEFAULT_OUT

    with open(infile, 'r') as f:
        t = Translator(f)
        t.translate()
        if args.dump:
            t.dump()
        t.wout(outfile)
