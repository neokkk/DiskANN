from argparse import ArgumentParser
import faiss
import numpy as np

def save_fvecs(filename, data):
    """
    Save a numpy array to .fvecs format.

    Parameters:
    - filename: str, output file name.
    - data: np.ndarray, data to save (shape: [n, d]).
    """
    n, d = data.shape
    with open(filename, 'wb') as f:
        for vector in data:
            # Write dimension as int32
            f.write(np.int32(d).tobytes())
            # Write vector as float32
            f.write(vector.astype('float32').tobytes())

def load_fvecs(filename):
    """
    Load a .fvecs file into a numpy array.

    Parameters:
    - filename: str, input file name.

    Returns:
    - np.ndarray, loaded data.
    """
    with open(filename, 'rb') as f:
        data = []
        while True:
            # Read dimension (int32)
            dim_bytes = f.read(4)
            if not dim_bytes:
                break
            dim = int(np.frombuffer(dim_bytes, dtype='int32')[0])
            # Read vector (float32)
            vector = np.frombuffer(f.read(4 * dim), dtype='float32')
            data.append(vector)
    return np.vstack(data)

def generate_datasets_and_groundtruth_fvecs(dimension, base_size, query_size, k, output_prefix="dataset"):
    """
    Generate synthetic datasets (base, query) and groundtruth using FAISS, saved as .fvecs.

    Parameters:
    - dimension: int, dimensionality of the vectors.
    - base_size: int, number of vectors in the base dataset.
    - query_size: int, number of vectors in the query dataset.
    - k: int, number of nearest neighbors to compute for groundtruth.
    - output_prefix: str, prefix for output files.

    Outputs:
    - Saves base, query, and groundtruth data to .fvecs and .ivecs files.
    """

    # Generate random base dataset
    print(f"Generating base dataset with {base_size} vectors of dimension {dimension}...")
    base_data = np.random.random((base_size, dimension)).astype('float32')

    # Generate random query dataset
    print(f"Generating query dataset with {query_size} vectors of dimension {dimension}...")
    query_data = np.random.random((query_size, dimension)).astype('float32')

    # Save datasets in .fvecs format
    save_fvecs(f"{output_prefix}_base.fvecs", base_data)
    save_fvecs(f"{output_prefix}_query.fvecs", query_data)
    print(f"Base and query datasets saved as {output_prefix}_base.fvecs and {output_prefix}_query.fvecs")

    # Build FAISS index for groundtruth computation
    print("Building FAISS index for groundtruth computation...")
    index = faiss.IndexFlatL2(dimension)  # L2 distance (Euclidean)
    index.add(base_data)  # Add base dataset to the index

    # Compute groundtruth (distances and indices)
    print(f"Computing groundtruth for top-{k} nearest neighbors...")
    distances, indices = index.search(query_data, k)

    # Save groundtruth
    save_fvecs(f"{output_prefix}_groundtruth_distances.fvecs", distances)
    np.save(f"{output_prefix}_groundtruth_indices.npy", indices)  # Save indices in numpy format
    print(f"Groundtruth saved as {output_prefix}_groundtruth_distances.fvecs and {output_prefix}_groundtruth_indices.npy")

def main():
    parser = ArgumentParser(description="Generate synthetic datasets and groundtruth for ANN evaluation.")
    parser.add_argument("-d", "--dimension", type=int, default=128, help="Dimensionality of the vectors.")
    parser.add_argument("-n", "--base_size", type=int, default=100000, help="Number of vectors in the base dataset.")
    parser.add_argument("-q", "--query_size", type=int, default=1000, help="Number of vectors in the query dataset.")
    parser.add_argument("-k", type=int, default=10, help="Number of nearest neighbors for groundtruth.")
    parser.add_argument("-o", "--output_prefix", type=str, default="out", help="Prefix for output files.")
    args = parser.parse_args()

    generate_datasets_and_groundtruth_fvecs(args.dimension, args.base_size, args.query_size, args.k, args.output_prefix)

if __name__ == "__main__":
    main()