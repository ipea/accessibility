#' @param group_by A `character` vector. When not `character(0)` (the default),
#'   indicates the `travel_matrix` columns that should be used to group the
#'   accessibility estimates by. For example, if `travel_matrix` includes a
#'   departure time column, that specifies the departure time of each entry in
#'   the data frame, passing `"departure_time"` to this parameter results in
#'   accessibility estimates grouped by origin and by departure time.
#'
#'   Accessibility is calculated separately for each unique combination of
#'   grouping variables. For constrained accessibility measures, each group is
#'   treated as an independent land-use-transportation system.
