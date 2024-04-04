# Script for testing the correctness of the Round Function
# implementation

# define the round function
from typing import List


def quarter_round(input_vec: List[int]) -> List[int]:
    input_a = input_vec[0]
    input_b = input_vec[1]
    input_c = input_vec[2]
    input_d = input_vec[3]

    mask = 0xffffffff

    # first ARX
    temp_d = ((input_a + input_b) & mask) ^ input_d
    inter_d = ((temp_d << 16) | (temp_d >> 16)) & mask
    inter_a = (input_a + input_b) & mask

    # second ARX
    temp_b = ((input_c + inter_d) & mask) ^ input_b
    inter_b = ((temp_b << 12) | (temp_b >> 20)) & mask
    inter_c = (input_c + inter_d) & mask

    # third ARX
    temp_d = ((inter_a + inter_b) & mask) ^ inter_d
    output_d = ((temp_d << 8) | (temp_d >> 24)) & mask
    output_a = (inter_a + inter_b) & mask

    # fourth ARX
    temp_b = ((inter_c + output_d) & mask) ^ inter_b
    output_b = ((temp_b << 7) | (temp_b >> 25)) & mask
    output_c = (inter_c + output_d) & mask

    return [output_a, output_b, output_c, output_d]

if __name__ == '__main__':
    input_test_vector = [0x0012DFFA, 0xAAFB4CD5, 0x18769012, 0xAFF22300]
    output_test_vector = quarter_round(input_test_vector)

    for i in output_test_vector:
        print(f'{i:08x}')

