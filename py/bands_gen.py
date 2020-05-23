#! /usr/bin/env python3

import argparse
import re
import sys

DEFAULT_BANDS = [
    35,
    48,
    61,
    74,
    87,
    100
    ]

TAB = "    "

HEADER = (
    "//\n" +
    "// This file was generated with bands_gen.py and should not be used outside of colorlib.inc\n" +
    "//\n" +
    "// Do not edit! Regenerate this file with bands_gen.py\n" +
    "//\n" +
    "\n" +
    "#if defined _bands_map_included\n" +
    TAB + "#endinput\n" +
    "#endif\n" +
    "#define _bands_map_included\n" +
    "\n"
    )

FOOTER = (
    "\n"
    )

ARRAY_DEF = "int {}[] = {{ {} }};\n"

STRING_DEF = 'char {}[] = "{}";\n'

def get_hex(i : int, n : int = 2) -> str:
    """Returns a hex representation of a char."""
    return '\\x' + '{:0{}x}'.format(i, n).upper()

def create_array(name : str, values : list) -> str:
    """Creates the definition for the enum for the mapping function."""
    av = ""
    for value in values[:-1]:
        av = av + str(value) + ', '

    for value in values[-1:]:
        av = av + str(value)

    return ARRAY_DEF.format(name, av)

def create_string(name : str, values : list) -> str:
    """Creates the definition for the enum for the mapping function."""
    sv = ""
    for value in values:
        sv = sv + get_hex(value)

    return STRING_DEF.format(name, sv)

def get_lut(bands : list) -> list:
    lut = []
    for i in range(0, 100):
        for j, b in enumerate(bands):
            if i <= b:
                lut.append(j)
                break

    return lut


def main():
    parser = argparse.ArgumentParser(description='Band Lut creator.')
    parser.add_argument(
        'out',
        type=argparse.FileType('w', encoding='UTF-8'),
        help='output path \'{path to include dir}/colorlib_map.inc\''
        )

    args = parser.parse_args()

    args.out.write(HEADER)
    args.out.write(create_array('g_iBands', DEFAULT_BANDS))
    args.out.write('\n')
    args.out.write(create_string('g_iBandLut', get_lut(DEFAULT_BANDS)))
    args.out.write(FOOTER)
    
    args.out.close()

if __name__ == '__main__':
    main()
