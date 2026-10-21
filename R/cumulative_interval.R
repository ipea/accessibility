#' Cumulative access based on maximum travel time interval
#'
#' Calculates the average or median number of opportunities that can be reached
#' considering multiple maximum travel cost thresholds within a given travel
#' cost interval specified by the user. The time interval cumulative
#' accessibility measure was originally proposed by
#' \insertCite{tomasiello2023time;textual}{accessibility}.
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @template travel_cost
#' @param interval A `numeric` vector of length 2. Indicates the start and end
#'   points of the interval of travel cost thresholds to be used. The first
#'   entry must be lower than the second.
#' @param interval_increment A `numeric`. How many travel cost units separate
#'   the cutoffs used to calculate the accessibility estimates which will be
#'   used to calculate the summary estimate within the specified interval.
#'   Should be thought as the resolution of the distribution of travel costs
#'   within the interval. Defaults to 1.
#' @param summary_function A function. This function is used to summarize a
#'   distribution of accessibility estimates within a travel cost interval as a
#'   single value. Can be any function that takes an arbitrary number of
#'   numeric values as input and returns a single number as output. Defaults
#'   to [stats::median()].
#' @template group_by
#' @template active
#' @param fill_missing_ids A `logical`. Origins (or destinations, when `active`
#'   is `FALSE`) that cannot reach any opportunity within the interval would
#'   not be included in the output. When `TRUE` (the default), the function
#'   includes them with an accessibility of 0.
#'
#' @template return_accessibility
#'
#' @family cumulative access
#'
#' @references
#' \insertAllCited{}
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' df <- cumulative_interval(
#'   travel_matrix = travel_matrix,
#'   land_use_data = land_use_data,
#'   interval = c(20, 30),
#'   opportunity = "schools",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' df <- cumulative_interval(
#'   travel_matrix = travel_matrix,
#'   land_use_data = land_use_data,
#'   interval = c(40, 80),
#'   opportunity = "jobs",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' @export
cumulative_interval <- function(travel_matrix,
                                land_use_data,
                                opportunity,
                                travel_cost,
                                interval,
                                interval_increment = 1,
                                summary_function = stats::median,
                                group_by = character(0),
                                active = TRUE,
                                fill_missing_ids = TRUE) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(travel_cost)
  checkmate::assert_logical(active, len = 1, any.missing = FALSE)
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)
  assert_interval_increment(interval_increment)
  assert_summary_function(summary_function)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(
    land_use_data,
    travel_matrix,
    opportunity,
    active = active
  )

  interval <- assert_and_assign_interval(interval)

  # if not a dt, keep original class to assign later when returning result

  if (!inherits(travel_matrix, "data.table")) {
    original_class <- class(travel_matrix)
    data <- data.table::as.data.table(travel_matrix)
  } else {
    data <- data.table::copy(travel_matrix)
  }

  if (!inherits(land_use_data, "data.table")) {
    land_use_data <- data.table::as.data.table(land_use_data)
  }

  # each interval is summarised over its own cutoffs only, which always include
  # the interval's upper limit (even if it's not a multiple of the increment).
  # accessibility is calculated once for the union of all cutoffs

  interval_cutoffs <- lapply(
    interval,
    function(pair) {
      unique(c(seq.int(pair[1], pair[2], by = interval_increment), pair[2]))
    }
  )
  cutoffs <- unique(unlist(interval_cutoffs))
  cutoffs <- cutoffs[order(cutoffs)]

  # small optimization: we can ditch anything that costs more than the highest
  # cost cutoff value, since it won't affect the results anyway
  .cost_colname <- travel_cost
  data <- data[get(.cost_colname) <= max(cutoffs)]

  merge_by_reference(
    data,
    land_use_data,
    opportunity,
    left_df_idcol = ifelse(active, "to_id", "from_id"),
    na_as_zero = TRUE
  )

  group_id <- ifelse(active, "from_id", "to_id")
  groups <- c(group_id, group_by)
  env <- environment()

  warn_extra_cols(travel_matrix, travel_cost, group_id, groups)

  # accessibility is calculated for every cutoff at once from the sums of
  # opportunities by cost bin. every combination of ids and groups gets a row
  # for each cutoff, with 0 opportunities where nothing is reached, otherwise
  # the summary measure would be miscalculated (e.g. think of median of 1 3 5
  # and median of 0 1 3 5)

  binned_sums <- sum_by_cost_bin(
    data,
    groups,
    opportunity,
    travel_cost,
    cutoffs
  )

  # ids that can't reach any opportunity at any cutoff are filled as well, and
  # only dropped at the end if fill_missing_ids is FALSE

  reached_ids <- unique(binned_sums[, ..groups])

  unique_values <- lapply(groups, function(x) unique(travel_matrix[[x]]))
  names(unique_values) <- groups

  grid_groups <- do.call(data.table::CJ, unique_values)

  access_list <- cumulative_sums_grid(
    binned_sums,
    grid_groups,
    groups,
    n_cutoffs = length(cutoffs),
    integer_opportunity = is.integer(data[[opportunity]])
  )
  data.table::set(access_list, j = "cutoffs", value = cutoffs[access_list$.bin])

  # the summary is returned as a double: summary functions such as median()
  # may return integers for some groups and doubles for others, and the summary
  # of opportunity counts doesn't have to be a whole number

  access_list <- lapply(
    interval_cutoffs,
    function(own_cutoffs) {
      access_list[
        cutoffs %in% own_cutoffs,
        .(access = as.numeric(summary_function(access))),
        by = eval(groups, envir = env)
      ]
    }
  )
  access <- data.table::rbindlist(access_list, idcol = "interval")

  if (!fill_missing_ids) {
    reached_rows <- access[reached_ids, on = groups, which = TRUE, nomatch = 0]
    access <- access[sort(reached_rows)]
  }

  data.table::setcolorder(access, c(groups, "interval", "access"))
  data.table::setnames(access, c(group_id, "access"), c("id", opportunity))

  if (length(interval) == 1) access[, interval := NULL]

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}
