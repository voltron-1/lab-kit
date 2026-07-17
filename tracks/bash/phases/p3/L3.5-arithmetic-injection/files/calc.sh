#!/usr/bin/env bash
# TEACHING SAMPLE — intentionally flawed
# calc.sh — double a quantity supplied on the command line.
n=$1                                  # UNTRUSTED
result=$(( n * 2 ))                   # $(( )) evaluates n as an arithmetic EXPRESSION,
                                      # and an array subscript inside it runs command substitution
echo "result=$result"
