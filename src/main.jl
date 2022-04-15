
function registration(
    destinationDir::String,
    filename::String,
    target::String,
    source::String,
    target_picked_points::Common.Points,
    source_picked_points::Common.Points,
    target_segment::String,
    source_segment::String,
    threshold::Float64,
    max_iteration::Int64
    )

    params = RegistrationArguments(
        destinationDir,
        filename,
        target,
        source,
        target_picked_points,
        source_picked_points,
        target_segment,
        source_segment,
        threshold,
        max_iteration,
    )

    PC_target = FileManager.las2pointcloud(params.target_segment)
    picked_target =
        Search.consistent_seeds(
            PC_target,
        ).([c[:] for c in eachcol(params.target_picked_points)])

    PC_source = FileManager.las2pointcloud(params.source_segment)
    picked_source =
        Search.consistent_seeds(
            PC_source,
        ).([c[:] for c in eachcol(params.source_picked_points)])


    ROTO, fitness, inlier_rmse, correspondence_set = Registration.ICP(
        PC_target.coordinates,
        PC_source.coordinates,
        picked_target,
        picked_source;
        threshold = params.threshold,
        max_it = params.max_iteration,
    )

    params.transformation = ROTO
    params.fitness = fitness
    params.inlier_rmse = inlier_rmse
    params.correspondence_set = correspondence_set

    saveAssets(params)

    return params
end
