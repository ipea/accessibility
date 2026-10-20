#' Concentration Index
#'
#' Calculates the Concentration Index (CI) of a given accessibility
#' distribution. This measures estimates the extent to which accessibility
#' inequalities are systematically associated with individuals' socioeconomic
#' levels. CI values can theoretically vary between -1 and +1 (when all
#' accessibility is concentrated in the most or in the least disadvantaged
#' person, respectively). Negative values indicate that inequalities favor the
#' poor, while positive values indicate a pro-rich bias. The function supports
#' calculating the standard relative CI and the corrected CI, as proposed by
#' \insertCite{erreygers2009correcting;textual}{accessibility}.
#'
#' @template accessibility_data
#' @template sociodem_data_with_income
#' @template opportunity_access
#' @template population
#' @param income A string. The name of the column in `sociodemographic_data`
#'   with the income variable that should be used to sort the population from
#'   the least to the most privileged. Please note that this variable should
#'   describe income per capita (e.g. mean income per capita, household income
#'   per capita, etc), instead of the total amount of income in each cell. Also
#'   note that, while income is generally used to rank population groups, any
#'   variable that can be used to describe one's socioeconomic status, such as
#'   education level, can be passed to this argument, as long as it can be
#'   numerically ordered (in which higher values denote higher socioeconomic
#'   status).
#' @param type A string. Which type of Concentration Index to calculate. Current
#'   available options are `"standard"` and `"corrected"`.
#' @template group_by_access
#'
#' @template return_inequality
#'
#' @family inequality
#'
#' @references
#' \insertAllCited{}
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' access <- cumulative_cutoff(
#'   travel_matrix,
#'   land_use_data,
#'   cutoff = 30,
#'   opportunity = "jobs",
#'   travel_cost = "travel_time"
#' )
#'
#' ci <- concentration_index(
#'   access,
#'   sociodemographic_data = land_use_data,
#'   opportunity = "jobs",
#'   population = "population",
#'   income = "income_per_capita",
#'   type = "corrected"
#' )
#' ci
#'
#' @export
concentration_index <- function(accessibility_data,
                                sociodemographic_data,
                                opportunity,
                                population,
                                income,
                                type,
                                group_by = character(0)) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(population)
  checkmate::assert_string(income)
  checkmate::assert(
    checkmate::check_string(type),
    checkmate::check_names(type, subset.of = c("standard", "corrected")),
    combine = "and"
  )
  assert_access_group_by(group_by)
  assert_accessibility_data(accessibility_data, opportunity, group_by)
  assert_sociodemographic_data(
    sociodemographic_data,
    accessibility_data,
    population = population,
    income = income
  )

  if (!inherits(accessibility_data, "data.table")) {
    original_class <- class(accessibility_data)
    data <- data.table::as.data.table(accessibility_data)
  } else {
    data <- data.table::copy(accessibility_data)
  }

  if (!inherits(sociodemographic_data, "data.table")) {
    sociodemographic_data <- data.table::as.data.table(sociodemographic_data)
  }

  merge_by_reference(
    data,
    sociodemographic_data,
    population,
    left_df_idcol = "id"
  )
  merge_by_reference(data, sociodemographic_data, income, left_df_idcol = "id")

  warn_extra_access_cols(accessibility_data, opportunity, group_by)

  # integer opportunities and population counts may overflow when multiplied,
  # so we convert them to doubles first

  .numeric_cols <- c(opportunity, population)
  data[, (.numeric_cols) := lapply(.SD, as.numeric), .SDcols = .numeric_cols]

  .opp_colname <- opportunity
  .pop_colname <- population
  .groups <- group_by

  data.table::setorderv(data, cols = c(income, group_by))

  # fractional rank calculation based on equation 4 of this paper:
  # Eddy van Doorslaer and Xander Koolman, https://doi.org/10.1002/hec.918

  # observations with the same income share the same rank: the midpoint of
  # their block in the cumulative population distribution. otherwise the result
  # would depend on the order of the rows

  data[, pop_share := get(.pop_colname) / sum(get(.pop_colname)), by = .groups]

  .income_colname <- income
  data[, .block_share := sum(pop_share), by = c(.groups, income)]
  data[
    ,
    fractional_rank := {
      first_in_block <- !duplicated(get(.income_colname))
      cumsum(.block_share * first_in_block) - .block_share / 2
    },
    by = .groups
  ]

  data[
    ,
    avg_access := stats::weighted.mean(
      get(.opp_colname),
      w = get(.pop_colname)
    ),
    by = .groups
  ]
  data[, diff_from_avg := get(.opp_colname) - avg_access]

  data[
    ,
    cont_to_total := (fractional_rank - 0.5) * diff_from_avg * pop_share /
      avg_access
  ]

  if (nrow(data) == 0 && identical(group_by, character(0))) {
    ci <- data.table::data.table(concentration_index = numeric(0))
  } else if (type == "standard") {
    ci <- data[
      ,
      .(concentration_index = 2 * sum(cont_to_total)),
      by = .groups
    ]
  } else if (type == "corrected") {
    # max()/min() may result in warnings if nrow(data) == 0
    data[, upper := suppressWarnings(max(get(.opp_colname))), by = .groups]
    data[, lower := suppressWarnings(min(get(.opp_colname))), by = .groups]

    # from Erreygers (2009), comparing equations 27 and 24, we have the
    # following correction factor
    # https://doi.org/10.1016/j.jhealeco.2008.02.003
    data[, correction_factor := 4 * avg_access / (upper - lower)]

    ci <- data[
      ,
      .(concentration_index = 2 * sum(cont_to_total * correction_factor)),
      by = .groups
    ]
  }

  if (exists("original_class")) class(ci) <- original_class

  return(ci)
}
