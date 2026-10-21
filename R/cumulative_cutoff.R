#' Cumulative access based on a travel cost cutoff
#'
#' Calculates the number of opportunities accessible under a given specified
#' travel cost cutoff.
#' @template description_generic_cost
#'
#' @template travel_matrix
#' @template land_use_data
#' @template opportunity
#' @param travel_cost A `character` vector. The name of the columns in
#'   `travel_matrix` with the travel costs between origins and destinations to
#'   be considered in the calculation.
#' @param cutoff Either a `numeric` vector or a list of `numeric` vectors, one
#'   for each cost specified in `travel_cost`. The travel cost cutoffs to
#'   consider when calculating accessibility levels. If a list, the function
#'   finds every single possible cutoff combination and uses them to calculate
#'   accessibility (e.g. if one specifies that travel time cutoffs should be 30
#'   and 60 minutes and that monetary cost cutoffs should be 5 and 10 dollars,
#'   the output includes accessibility estimates limited at 30 min & 5 dollars,
#'   30 min & 10 dollars, 60 min & 5 dollars and 60 min & 10 dollars). In these
#'   cases, cost constraints are considered simultaneously - i.e. only trips
#'   that take 30 minutes or less AND 5 dollars or less to be completed, for
#'   example, are included in the accessibility output. The cutoff parameter is
#'   not included in the final output if the input includes only a single cutoff
#'   for a single travel cost.
#' @template group_by
#' @template active
#' @param fill_missing_ids A `logical`. Calculating cumulative accessibility may
#'   result in missing ids if they cannot reach any of the destinations
#'   within the specified travel cost cutoff. For example, using a travel time
#'   cutoff of 20 minutes, when estimating the accessibility of origin `A` that
#'   can only reach destinations with more than 40 minutes results in id `A`
#'   not being included in the output. When `TRUE` (the default), the function
#'   identifies which origins would be left out and fills their respective
#'   accessibility values with 0, which incurs a performance penalty.
#'
#' @template return_accessibility
#'
#' @family cumulative access
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' # active accessibility: number of schools accessible from each origin
#' df <- cumulative_cutoff(
#'   travel_matrix = travel_matrix,
#'   land_use_data = land_use_data,
#'   cutoff = 30,
#'   opportunity = "schools",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' df <- cumulative_cutoff(
#'   travel_matrix = travel_matrix,
#'   land_use_data = land_use_data,
#'   cutoff = c(30, 60),
#'   opportunity = "schools",
#'   travel_cost = "travel_time"
#' )
#' head(df)
#'
#' # passive accessibility: number of people that can reach each destination
#' df <- cumulative_cutoff(
#'   travel_matrix = travel_matrix,
#'   land_use_data = land_use_data,
#'   cutoff = 30,
#'   opportunity = "population",
#'   travel_cost = "travel_time",
#'   active = FALSE
#' )
#' head(df)
#'
#' # using multiple travel costs
#' pareto_frontier <- readRDS(file.path(data_dir, "pareto_frontier.rds"))
#'
#' df <- cumulative_cutoff(
#'   pareto_frontier,
#'   land_use_data = land_use_data,
#'   opportunity = "jobs",
#'   travel_cost = c("travel_time", "monetary_cost"),
#'   cutoff = list(c(20, 30), c(0, 5, 10))
#' )
#' head(df)
#'
#' @export
cumulative_cutoff <- function(travel_matrix,
                              land_use_data,
                              opportunity,
                              travel_cost,
                              cutoff,
                              group_by = character(0),
                              active = TRUE,
                              fill_missing_ids = TRUE) {

  checkmate::assert_string(opportunity)
  checkmate::assert_character(
    travel_cost,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE
  )
  checkmate::assert_logical(active, len = 1, any.missing = FALSE)
  checkmate::assert_logical(fill_missing_ids, len = 1, any.missing = FALSE)
  assert_cutoff(cutoff, travel_cost)
  assert_group_by(group_by)
  assert_travel_matrix(travel_matrix, travel_cost, group_by)
  assert_land_use_data(
    land_use_data,
    travel_matrix,
    opportunity,
    active = active
  )

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

  merge_by_reference(
    data,
    land_use_data,
    opportunity,
    left_df_idcol = ifelse(active, "to_id", "from_id"),
    na_as_zero = TRUE
  )

  group_id <- ifelse(active, "from_id", "to_id")
  groups <- c(group_id, group_by)
  warn_extra_cols(travel_matrix, travel_cost, group_id, groups)

  cutoff_list <- if (is.list(cutoff)) {
    cutoff
  } else {
    list(cutoff)
  }
  names(cutoff_list) <- travel_cost
  cutoff_df <- do.call(data.table::CJ, cutoff_list)

  env <- environment()
  .opportunity_colname <- opportunity

  access <- do.call(
    mapply,
    args = c(
      as.list(cutoff_df),
      SIMPLIFY = FALSE,
      FUN = function(...) {
        cutoff_args <- list(...)

        # the filter and the cutoff columns use the exact cutoff values, which
        # must match the values used to fill missing ids later. NA costs count
        # as not reachable

        within_cutoffs <- Reduce(
          `&`,
          Map(
            function(cost, value) data[[cost]] <= value,
            names(cutoff_args),
            cutoff_args
          )
        )

        cum_opps <- data[within_cutoffs]

        if (length(travel_cost) > 1) {
          .od_group <- c(setdiff(groups, group_id), "from_id", "to_id")
          cum_opps <- cum_opps[cum_opps[, .I[1], by = .od_group]$V1]
        }

        cum_opps <- cum_opps[
          ,
          .(access = sum(get(.opportunity_colname))),
          by = eval(groups, envir = env)
        ]

        for (cost in names(cutoff_args)) {
          data.table::set(cum_opps, j = cost, value = cutoff_args[[cost]])
        }

        cum_opps
      }
    )
  )

  access <- data.table::rbindlist(access)

  if (fill_missing_ids) {
    unique_values <- lapply(groups, function(x) unique(travel_matrix[[x]]))
    names(unique_values) <- groups
    unique_values <- append(unique_values, cutoff_list)

    possible_combinations <- do.call(data.table::CJ, unique_values)

    if (nrow(access) < nrow(possible_combinations)) {
      access <- do_fill_missing_ids(
        access,
        possible_combinations,
        groups = c(groups, travel_cost)
      )
    }
  }

  data.table::setnames(access, c(group_id, "access"), c("id", opportunity))
  data.table::setcolorder(
    access,
    c("id", setdiff(groups, group_id), travel_cost, opportunity)
  )
  data.table::setorderv(access, c("id", setdiff(groups, group_id), travel_cost))

  env <- environment()
  if (length(travel_cost) == 1 && length(cutoff) == 1) {
    access[, get("travel_cost", envir = env) := NULL]
  }

  if (exists("original_class")) class(access) <- original_class

  return(access[])
}
