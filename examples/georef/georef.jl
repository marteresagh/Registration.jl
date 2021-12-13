using Visualization
using Registration
using Common
using FileManager

path_target_points = raw"C:\Users\marte\Documents\Julia_package\UTILS\georef\PUNTI_COORD_GEO_txt.json"
target_points = FileManager.load_points(path_target_points)

path_source_points = raw"C:\Users\marte\Documents\Julia_package\UTILS\georef\PUNTI_CORD_LOCALI_txt.json"
source_points = FileManager.load_points(path_source_points)

PC_source = FileManager.source2pc(
    raw"C:\Users\marte\Documents\Julia_package\UTILS\georef\FETTA_DI_CAVA2.las",
    0,
) # your path


Visualization.VIEW([
    Visualization.points(source_points; color = Visualization.COLORS[2])
    Visualization.points(PC_source.coordinates, PC_source.rgbs)
]);

ROTO, fitness, rmse, corr_set =
    Registration.compute_transformation(target_points, source_points)

Visualization.VIEW([
    Visualization.points(source_points; color = Visualization.COLORS[2])
    Visualization.points(PC_source.coordinates, PC_source.rgbs)
]);
