#!/usr/bin/env python3
# Copyright    2022  Xiaomi Corp.        (authors: Fangjun Kuang)

import argparse
import json


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--enable-cuda",
        action="store_true",
        default=False,
        help="True to enable CUDA",
    )

    parser.add_argument(
        "--is-macos",
        action="store_true",
        default=False,
        help="True to for macos",
    )

    parser.add_argument(
        "--test-only-latest-torch",
        action="store_true",
        default=False,
        help="""If True, we test only the latest PyTorch
        to reduce CI running time.""",
    )
    return parser.parse_args()


def generate_build_matrix(enable_cuda, test_only_latest_torch, is_macos):
    matrix = {
        # there are issues in serializing ragged tensors in 1.5.0 and 1.5.1
        #  "1.5.0": {
        #      "python-version": ["3.6", "3.7", "3.8"],
        #      "cuda": ["10.1", "10.2"],
        #  },
        #  "1.5.1": {
        #      "python-version": ["3.6", "3.7", "3.8"],
        #      "cuda": ["10.1", "10.2"],
        #  },
        "1.6.0": {
            "python-version": ["3.6", "3.7", "3.8"],
            "cuda": ["10.1", "10.2"],
        },
        "1.7.0": {
            "python-version": ["3.6", "3.7", "3.8"],
            "cuda": ["10.1", "10.2", "11.0"],  # default 10.2
        },
        "1.7.1": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.1", "10.2", "11.0"],  # default 10.2
        },
        "1.8.0": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.1", "10.2", "11.1"],  # default 10.2
        },
        "1.8.1": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.1", "10.2", "11.1"],  # default 10.2
        },
        "1.9.0": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.2", "11.1"],  # default 10.2
        },
        "1.9.1": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.2", "11.1"],  # default 10.2
        },
        "1.10.0": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.2", "11.1", "11.3"],
        },
        "1.10.1": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.2", "11.1", "11.3"],  # default 10.2
        },
        "1.10.2": {
            "python-version": ["3.6", "3.7", "3.8", "3.9"],
            "cuda": ["10.2", "11.1", "11.3"],  # default 10.2
        },
        "1.11.0": {
            "python-version": ["3.7", "3.8", "3.9", "3.10"],
            "cuda": ["10.2", "11.3", "11.5"],  # default 10.2
        },
        "1.12.0": {
            "python-version": ["3.7", "3.8", "3.9", "3.10"],
            "cuda": ["10.2", "11.3", "11.6"],  # default 10.2
        },
        "1.12.1": {
            "python-version": ["3.7", "3.8", "3.9", "3.10"],
            "cuda": ["10.2", "11.3", "11.6"],  # default 10.2
        },
        "1.13.0": {
            "python-version": ["3.7", "3.8", "3.9", "3.10", "3.11"],
            "cuda": ["11.6", "11.7"],  # default 11.7
        },
        "1.13.1": {
            "python-version": ["3.7", "3.8", "3.9", "3.10", "3.11"],
            "cuda": ["11.6", "11.7"],  # default 11.7
        },
        "2.0.0": {
            "python-version": ["3.8", "3.9", "3.10", "3.11"],
            "cuda": ["11.7", "11.8"],  # default 11.7
        },
        "2.0.1": {
            "python-version": ["3.8", "3.9", "3.10", "3.11"],
            "cuda": ["11.7", "11.8"],  # default 11.7
        },
    }
    if test_only_latest_torch:
        latest = "2.0.1"
        matrix = {latest: matrix[latest]}

    if is_macos:
        assert enable_cuda is False

    # We only have limited spaces in anaconda, so we exclude some
    # versions of PyTorch here. If you need them, please consider
    # installing k2 from source
    # Only CUDA build are excluded since it occupies more disk space
    #  excluded_torch_versions = ["1.6.0", "1.7.0", "1.7.1", "1.8.0", "1.8.1"]
    #  excluded_torch_versions += ["1.9.0", "1.9.1"]
    excluded_torch_versions = []

    excluded_python_versions = []
    enabled_cuda_versions = ["10.2", "11.6", "11.7", "11.8"]
    enabled_python_versions = []

    ans = []
    for torch, python_cuda in matrix.items():
        if torch in excluded_torch_versions and enable_cuda:
            continue

        python_versions = python_cuda["python-version"]
        cuda_versions = python_cuda["cuda"]

        if enable_cuda:
            for p in python_versions:
                if p in excluded_python_versions:
                    continue
                for c in cuda_versions:
                    if enabled_cuda_versions and c not in enabled_cuda_versions:
                        continue
                    ans.append(
                        {
                            "torch": torch,
                            "python-version": p,
                            "cuda": c,
                            "image": f"pytorch/manylinux-builder:cuda{c}",
                        }
                    )
        else:
            for p in python_versions:
                if p in excluded_python_versions:
                    continue
                if enabled_python_versions and p not in enabled_python_versions:
                    continue
                if is_macos:
                    p = "cp" + "".join(p.split("."))
                    ans.append(
                        {
                            "torch": torch,
                            "python-version": p,
                        }
                    )
                else:
                    ans.append(
                        {
                            "torch": torch,
                            "python-version": p,
                            "image": f"pytorch/manylinux-builder:cuda10.2",
                        }
                    )

    print(json.dumps({"include": ans}))


def main():
    args = get_args()
    generate_build_matrix(
        enable_cuda=args.enable_cuda,
        test_only_latest_torch=args.test_only_latest_torch,
        is_macos=args.is_macos,
    )


if __name__ == "__main__":
    main()
