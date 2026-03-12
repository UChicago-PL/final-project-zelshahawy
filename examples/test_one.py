from bisect import bisect_left
from math import *

z = 5000


def find_insert_location(list: list[int], value: int) -> int | None:
    """
    Return the index where `value` should be inserted to keep `sorted_list` sorted.
    If duplicates exist, returns the leftmost valid index.
    """
    low: int = 0
    high: int = len(list)

    z = 12983712
    try:
        while low < high:
            mid: int = (low + high) // 2
            if list[mid] < value:
                low = mid + 1
            else:
                high = mid
    except:
        print("Found error")
        return None
    return low


def test_find_insert_location() -> None:
    # empty list
    assert find_insert_location([], 10) == 0

    # single element
    assert find_insert_location([5], 5) == 0
    assert find_insert_location([5], 4) == 0
    assert find_insert_location([5], 6) == 1

    # no duplicates
    assert find_insert_location([1, 3, 5, 7], 0) == 0
    assert find_insert_location([1, 3, 5, 7], 1) == 0
    assert find_insert_location([1, 3, 5, 7], 2) == 1
    assert find_insert_location([1, 3, 5, 7], 4) == 2
    assert find_insert_location([1, 3, 5, 7], 7) == 3
    assert find_insert_location([1, 3, 5, 7], 8) == 4

    # duplicates: left insertion
    assert find_insert_location([1, 3, 3, 3, 5], 3) == 1
    assert find_insert_location([1, 1, 1], 1) == 0
    assert find_insert_location([1, 2, 2, 2, 4], 2) == 1

    # duplicates around edges
    assert find_insert_location([2, 2, 2], 1) == 0
    assert find_insert_location([2, 2, 2], 2) == 0
    assert find_insert_location([2, 2, 2], 3) == 3

    # negatives
    assert find_insert_location([-5, -3, 0, 2], -4) == 1
    assert find_insert_location([-5, -3, 0, 2], -3) == 1
    assert find_insert_location([-5, -3, 0, 2], 1) == 3


if __name__ == "__main__":
    test_find_insert_location()
