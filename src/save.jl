function saveAssets(params::RegistrationArguments)

    cloud_S = FileManager.CloudMetadata(params.source)
    tbb_source = cloud_S.tightBoundingBox
    transformedBB = Common.apply_matrix(params.transformation, Common.getmodel(tbb_source)[1])

    cloud_T = FileManager.CloudMetadata(params.target)
    tbb_target = cloud_T.tightBoundingBox

    aabb = Common.AABB(transformedBB)
    Common.update_boundingbox!(aabb, tbb_target)

    params.aabb = aabb

    files_source = FileManager.get_all_values(FileManager.potree2trie(params.source))
    files_target = FileManager.get_all_values(FileManager.potree2trie(params.target))
    total_points = cloud_S.points + cloud_T.points

    # creo l'header
    println("Point cloud: saving ...")
    mainHeader = FileManager.newHeader(
        aabb,
        "REGISTRATION",
        FileManager.SIZE_DATARECORD,
        total_points,
    )
    # apro il las
    t = open(joinpath(params.destinationDir, params.filename), "w")
    write(t, Registration.LasIO.magic(Registration.LasIO.format"LAS"))
    write(t, mainHeader)

    println("Save source points...")
    for file in files_source
        h, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            plas = FileManager.newPointRecord(
                laspoint,
                h,
                Registration.LasIO.LasPoint2,
                mainHeader;
                affineMatrix = params.transformation,
            )
            write(t, plas)
        end
        flush(t)
    end

    println("Save target points...")
    for file in files_target
        h, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            plas = FileManager.newPointRecord(
                laspoint,
                h,
                Registration.LasIO.LasPoint2,
                mainHeader,
            )
            write(t, plas)
        end
        flush(t)
    end

    close(t)

    println("Point cloud: done ...")
    return 0
end
