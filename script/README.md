# Script Usage

## registration.jl

Return affine transformation to combine two point clouds into a global consistent model.

In the Iterative Closest Point one point cloud the reference, or target, is kept fixed,
while the other one, the source, is transformed to best match the reference.

#### Input parameters description:
 - target: Potree of target
 - source: Potree of source
 - outfolder: output folder
 - projname: project name
 - picked_target: a text file with points list of target (coordinates by row)
 - picked_source: a text file with points list of source (coordinates by row)
 - threshold: maximum distance of the nearest neighbor
 - scale: scale factor for bounding box of picked points  

#### Output:
  - `projname.txt`: a text file with affine transformation written by row
  - `projname.las`: point clouds registered
  - `target_segment.las`: limited target (points used for calculation)
  - `source_segment.las`: limited source (points used for calculation)
  - `execution.probe`:
      - fitness: which measures the overlapping area, the higher the better. (# of inlier correspondences / # of points in target).
      - inlier_rmse: which measures the RMSE of all inlier correspondences. The lower the better.
      - correspondence_set: # of inlier correspondences.

#### Options:
```
$ julia registration.jl -h

usage: registration.jl -t PICKED_TARGET -s PICKED_SOURCE -o OUTFOLDER
                       -p PROJNAME [--threshold THRESHOLD]
                       [--scale SCALE] [-h] target source

positional arguments:
 target                Target points
 source                Source points

optional arguments:
 -t, --picked_target PICKED_TARGET
                       Picked target points
 -s, --picked_source PICKED_SOURCE
                       Picked source points
 -o, --outfolder OUTFOLDER
                       Output folder project
 -p, --projname PROJNAME
                       Project name
 --threshold THRESHOLD
                       Distance threshold (type: Float64, default:
                       0.03)
 --scale SCALE         Scale factor of BB (type: Float64, default:
                       1.3)
 -h, --help            show this help message and exit
```

#### Examples:

    # registration LAS
    julia registration.jl -t "C:\picked_points_target.txt" -s "C:\picked_points_source.txt" -o "C:\PROJ_FOLDER" -p "TEST001" "C:\target_potree" "C:\source_potree"

    # registration LAS with different threshold
    julia registration.jl -t "C:\picked_points_target.txt" -s "C:\picked_points_source.txt" -o "C:\PROJ_FOLDER" -p "TEST001" --threshold 0.02 "C:\target_potree" "C:\source_potree"
