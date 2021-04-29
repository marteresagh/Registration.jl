# Script Usage

## registration.jl

Return affine transformation to combine two point clouds into a global consistent model.

In the Iterative Closest Point one point cloud the reference, or target, is kept fixed,
while the other one, the source, is transformed to best match the reference.

#### Input parameters description:
 - target: LAS/Potree of target
 - source: LAS/Potree of source
 - output: output filename
 - picked_target: a text file with points list of target (coordinates by row)
 - picked_source: a text file with points list of source (coordinates by row)
 - threshold: maximum distance of the nearest neighbor
 - lod: level of detail of potree project

#### Output:
  - `output.txt`: a text file with affine transformation written by row

#### Options:
```
$ julia registration.jl -h

usage: registration.jl -t PICKED_TARGET -s PICKED_SOURCE -o OUTPUT
                       [--threshold THRESHOLD] [--lod LOD] [-h] target
                       source

positional arguments:
  target                Target points
  source                Source points

optional arguments:
  -t, --picked_target PICKED_TARGET
                        Picked target points
  -s, --picked_source PICKED_SOURCE
                        Picked source points
  -o, --output OUTPUT   Output filename (.txt)
  --threshold THRESHOLD
                        Distance threshold (default: 0.03)
  --lod LOD             Level of detail (default: 0)
  -h, --help            show this help message and exit
```

#### Examples:

    # registration LAS
    julia registration.jl -t "C:\picked_points_target.txt" -s "C:\picked_points_source.txt" -o "C:\matrix.txt" "C:\target.las" "C:\source.las"

    # registration LAS with different threshold
    julia registration.jl -t "C:\picked_points_target.txt" -s "C:\picked_points_source.txt" -o "C:\matrix.txt" --threshold 0.02 "C:\target.las" "C:\source.las"
