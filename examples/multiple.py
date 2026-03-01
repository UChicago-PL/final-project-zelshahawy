from math import *
from collections import deque


def f(x=[]):
    try:
        x.append(1)
    except:
        raise ValueError("Couldn't append")
    return x

