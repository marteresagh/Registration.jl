mutable struct RegistrationArguments
    destinationDir::String
    filename::String
    target::String
    source::String
    target_picked_points::Common.Points
    source_picked_points::Common.Points
    target_segment::String
    source_segment::String
    threshold::Float64
    max_iteration::Int64
    transformation::Matrix{Float64}
    fitness::Float64
    inlier_rmse::Float64
    correspondence_set::Matrix{Int32}
    aabb::Common.AABB


    # parametri che passa l'utente
    function RegistrationArguments(
        destinationDir::String,
        filename::String,
        target::String,
        source::String,
        target_picked_points::Common.Points,
        source_picked_points::Common.Points,
        target_segment::String,
        source_segment::String,
        threshold::Float64,
        max_iteration::Int64,
    )

        transformation = Matrix{Float64}(Common.I,4,4)
        fitness = Inf
        inlier_rmse = Inf
        correspondence_set = Matrix{Int32}(Common.I, 2,2)

        return new(
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
            transformation,
            fitness,
            inlier_rmse,
            correspondence_set,
            Common.AABB()
        )
    end

end
