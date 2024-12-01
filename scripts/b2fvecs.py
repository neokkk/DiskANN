import argparse
import numpy as np
import os

def read_bvecs(filename):
    with open(filename, "rb") as f:
        dim = np.fromfile(f, dtype=np.int32, count=1)[0]  # first 4 bytes is dim
        print(f"dim: {dim}")
        f.seek(0)
        data = np.fromfile(f, dtype=np.uint8).reshape(-1, dim + 4)
        print(f"num_vectors: {data.size}")
    return data[:, 4:]  # ignore first 4 bytes

def write_fvecs(data, filename):
    with open(filename, "wb") as f:
        for vector in data:
            f.write(np.array([len(vector)], dtype=np.int32).tobytes())  # vector size
            f.write(vector.astype(np.float32).tobytes())  # vector data

def main():
    parser = argparse.ArgumentParser(description="Read vectors from a bvec file.")
    parser.add_argument("input", type=str)
    parser.add_argument("output", type=str)
    args = parser.parse_args()

    print(args)

    input = args.input
    output = args.output

    if not input:
        print("Input .fvecs")
        exit(1)

    if not output:
        base, _ = os.path.splitext(input)
        output = f"{base}.fvecs"

    bvecs_data = read_bvecs(input)
    fvecs_data = bvecs_data.astype(np.float32)
    write_fvecs(fvecs_data, output)
    print("Succeed to convert bvecs to fvecs")

if __name__ == "__main__":
    main()
