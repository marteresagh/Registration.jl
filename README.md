# Registration

This package implements point cloud registration. It uses the Python package [Open3D](http://www.open3d.org/docs/release/) to perform the actual calculation.

## Installation
Installation is straightforward: enter Pkg mode by hitting `]`, and then
```julia-repl
(v1.4) pkg> add https://github.com/marteresagh/Registration.jl
```

This package use [PyCall](https://github.com/JuliaPy/PyCall.jl) to provides the ability to directly call and fully interoperate with Python from the Julia language.
It is necessary to install [Open3D](http://www.open3d.org/docs/release/getting_started.html) in your specified Python version.
