from multiprocessing import Pool
from functools import reduce
import math

def f(x):
    return reduce(lambda a, b: math.log(a+b), range(10**5), x)

if __name__ == '__main__':
    pool = Pool(processes=6)            
    result = pool.map(f, range(10000000))  

