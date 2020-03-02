def calc_sieve(limit):
    sieve = [False] * limit
    x = 1
    while x * x < limit:
        y = 1
        while y * y < limit:

            # Main part of
            # Sieve of Atkin
            n = (4 * x * x) + (y * y)
            if (n <= limit and (n % 12 == 1 or n % 12 == 5)):
                print('A%04x[%05d] ' % (n, n), end='')
                sieve[n] ^= True
                if n == 11:
                    print('5!')
                    pass

            n = (3 * x * x) + (y * y)
            if n <= limit and n % 12 == 7:
                print('B%04x[%05d] ' % (n, n), end='')
                sieve[n] ^= True
                if n == 11:
                    print('5!')
                    pass

            n = (3 * x * x) - (y * y)
            if x > y:
                # print('%04x' % n, end='')
                if n <= limit and n % 12 == 11:
                    print('C%04x[%05d] ' % (n, n), end='')
                    # print('!', end='')
                    sieve[n] ^= True
                    if n == 11:
                        print('5!')
                        pass
                # print(' ', end='')
            y += 1
        x += 1
    # print('')

    # Mark all multiples of
    # squares as non-prime
    r = 5
    for r in range(r, 16):
        # print('R%d ' % r, end='')
        if sieve[r]:
            for i in range(r * r, limit, r * r):
                # print('D%d ' % i, end='')
                sieve[i] = False

    # Print primes
    # using sieve[]
    for i, v in enumerate(sieve):
        print('1' if v else '0', end='')
        if (i % 16) == 0:
            print(' ', end='')
        elif (i % 8) == 0:
            print('_', end='')
    print('\nDONE')
    for a in range(5, limit):
        if sieve[a]:
            print(a, end=" ")


"""
FULL:
0000 0000 0000 0000 0000 0000 0000 2208 2A80 0880 A200 2880 8AA0 A020 0A08 0280
A228 0A00 8A80 2028 2288 88A0 A028 DF02 1010 0000 0D00 2E0A 6D2E 7465 7973 2073
306D 1B5B 5343 4F49 366D 5B33 6D1B 5B31 201B 6E67 7469 6F6F 4842 1B5B 1B63 0000

     0123 4567 89AB CDEF
1010 0001 0000 0001 0000
DF02 1101 1111 0000 0010
A028 1010 0000 0010 1000   00001010_00101000
88A0 1000 1000 1010 0000   10100010_10001010
2288   10 0010 1000 1000   00001000_10100010
EMPTY:

0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000D002E0A6D2E746579732073
306D1B5B53434F49366D5B336D1B5B31201B6E6774696F6F48421B5B1B630000

 5  7  13  19  29  53  67  85  103  125  173  199  229  17  11  25  41  65  97  137  185  241  37  31  23  43  61  85  91  127  157  205  223  65  47  73  89  113  145  185  233  101  79  71  109  91  59  125  149  139  181  175  221  145  107  169  83  193  197  151  143  205  163  131  221  245  211  247  191  167  143  247  239  227  179  251              
A5 B7 A13 B19 A29 A53 B67 A85 B103 A125 A173 B199 A229 A17 C11 A25 A41 A65 A97 A137 A185 A241 A37 B31 C23 B43 A61 A85 B91 B127 A157 A205 B223 A65 C47 A73 A89 A113 A145 A185 A233 A101 B79 C71 A109 B91 C59 A125 A149 B139 A181 B175 A221 A145 C107 A169 C83 A193 A197 B151 C143 A205 B163 C131 A221 A245 B211 B247 C191 C167 C143 B247 C239 C227 C179 C251


    5 7 11 13 17 19 23 25 29 31    37 41 43 47 53 59 61    67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 169 173 175 179 181 191 193 197 199 211 223 227 229 233 239 241 245 251                                                                                           
    5 7 11 13    19 23    29 31 33 37    43 47 53 59 61 65 67 71    79 81 83    97 101 103 107 109 113 127 129 131     139 149 151 157 161 163 167     173 175 179 181 191 193 197 199 211 223 225 227 229 239     241 245 251
    5 7 11 13 17 19 23 25 29 31    37 41 43 47 53 59 61    67 71 73 79    83 89 97 101 103 107 109 113 127     131 137 139 149 151 157     163 167 169 173 175 179 181 191 193 197 199 211 223     227 229 233 239 241 245 251
2 3 5 7 11 13 17 19 23    29 31    37 41 43 47 53 59 61    67 71 73 79    83 89 97 101 103 107 109 113 127     131 137 139 149 151 157     163 167     173     179 181 191 193 197 199 211 223     227 229 233 239 241     251
"""


"""
ROM0:



"""


def rus_peasant(A, B):
    """
    X = B;
    while (X <= A/2) X <<= 1;
    while (A >= B) {
        if (A >= X) A -= X;
        X >>= 1;
    }
    Modulus in A
    :param a:
    :param b:
    :return:
    """
    X = B
    while X <= A / 2:
        X <<= 1
    print('A: {:04X} {:04X} {:04X}'.format(A, X, B))
    while A >= B:
        if A >= X:
            A -= X
        X >>= 1
        print('B: {:04X} {:04X}'.format(A, X))
    return A, X


'''
029A 0030
029A 0030
014D 0180
029A 0180  <-- A
011A 0040
00DA 0020
00BA 0010
00AA 0008
00A2 0004
009E 0002
009C 0001
'''

def div16(a, b):
    from bitstring import BitArray
    ab = bin(a)[2:]
    ab = '0'*(16-len(ab)) + ab
    bb = bin(b)[2:]
    bb = '0' * (8 - len(bb)) + bb
    N = BitArray(bin=ab)
    D = BitArray(bin=bb)

    R = BitArray(16)
    Q = BitArray(16)
    for i in range(16):
        R = R << 1
        R[15] = N[i]
        print('R='+R.hex, end='')
        print(' D=' + D.hex, end='')
        if R.uint >= D.uint:
            R = BitArray(bin=bin(R.uint - D.uint))
            R = BitArray(bin="0" * (16 - len(R)) + R.bin)
            Q[i] = True
        print()
    return Q.uint, R.uint

def div8(a, b):
    from bitstring import BitArray
    ab = bin(a)[2:]
    ab = '0'*(17-len(ab)) + ab
    bb = bin(b)[2:]
    bb = '0' * (9 - len(bb)) + bb
    rd1 = BitArray(bin=ab)
    rd2 = BitArray(bin=bb)
    re = BitArray(bin="0 0000 0000 0000 0000")
    rd1u = BitArray(bin="0 0000 0000")
    c = False

    while not c:
        rd1 = rd1 << 1
        rd1u = rd1u << 1
        rd1u[-1] = rd1[0]
        c = rd1u[0]

        __rd1 = rd1u[1:-1].uint
        __rd2 = rd2[1:-1].uint

        if c:
            # jump to div8b
            rd1u = BitArray(bin=bin(__rd1 - __rd2))
            rd1u = BitArray(bin="0" * (9 - len(rd1u)) + rd1u.bin)
            c = True
        elif __rd1 > __rd2:
            # jump to div8b
            rd1u = BitArray(bin=bin(__rd1 - __rd2))
            rd1u = BitArray(bin="0" * (9 - len(rd1u)) + rd1u.bin)
            c = True
        else:
            c = False
        re = re << 1
        re[-1] = c
        c = re[0]

    return re[1:-1].uint


if __name__ == '__main__':
    # d, r = div16(5, 16)
    # print("%d and %d" % (d, r))
    # pass
    calc_sieve(2**16)

    # calc(255)
    # res = rus_peasant(666, 48)[0]
    # print('{:04X}'.format(res))
