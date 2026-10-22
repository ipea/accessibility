#' Palma Ratio
#'
#' Calculates the Palma Ratio of a given accessibility distribution. Originally
#' defined as the income share of the richest 10% of a population divided by the
#' income share of the poorest 40%, this measure has been adapted in transport
#' planning as the average accessibility of the richest 10% divided by the
#' average accessibility of the poorest 40%.
#'
#' @template accessibility_data
#' @template sociodem_data_with_income
#' @template opportunity_access
#' @template population
#' @param income A string. The name of the column in `sociodemographic_data`
#'   with the income variable that should be used to classify the population in
#'   socioeconomic groups. Please note that this variable should describe income
#'   per capita (e.g. mean income per capita, household income per capita, etc),
#'   instead of the total amount of income in each cell.
#' @template group_by_access
#'
#' @template return_inequality
#'
#' @family equity
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
#' palma <- palma_ratio(
#'   access,
#'   sociodemographic_data = land_use_data,
#'   opportunity = "jobs",
#'   population = "population",
#'   income = "income_per_capita"
#' )
#' palma
#'
#' @export
palma_ratio <- function(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  income,
  group_by = character(0)
) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(population)
  checkmate::assert_string(income)
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

  # normwt = TRUE treats population as relative weights, so the quantiles don't
  # depend on its scale (e.g. counts vs. shares). integer weights are converted
  # to doubles, because Hmisc multiplies them by the number of observations,
  # which may overflow

  income_quantiles <- Hmisc::wtd.quantile(
    sociodemographic_data[[income]],
    weights = as.numeric(sociodemographic_data[[population]]),
    probs = c(0.4, 0.9),
    normwt = TRUE
  )

  .income_colname <- income
  data[
    get(.income_colname) <= income_quantiles["40%"],
    .palma_group := "poorest"
  ]
  data[
    get(.income_colname) > income_quantiles["90%"],
    .palma_group := "wealthiest"
  ]

  .opportunity_colname <- opportunity
  .population_colname <- population
  .groups <- group_by

  wealthiest_access <- data[
    .palma_group == "wealthiest",
    .(
      avg_access = stats::weighted.mean(
        get(.opportunity_colname),
        w = get(.population_colname)
      )
    ),
    by = .groups
  ]
  poorest_access <- data[
    .palma_group == "poorest",
    .(
      avg_access = stats::weighted.mean(
        get(.opportunity_colname),
        w = get(.population_colname)
      )
    ),
    by = .groups
  ]

  if (identical(group_by, character(0))) {
    pr <- if (
      (nrow(wealthiest_access) == 0 || nrow(poorest_access) == 0) &&
        nrow(data) > 0
    ) {
      NA_real_
    } else {
      wealthiest_access$avg_access / poorest_access$avg_access
    }

    palma <- data.table::data.table(palma_ratio = pr)
  } else {
    # if wealthiest_access is missing data on any of the groups, the result is
    # that this group will be missing from the final output, even though its
    # palma should be NA. thus, we have to fill wealthiest_access with missing
    # groups

    wealthiest_access <- fill_groups(wealthiest_access, data, group_by)

    palma <- wealthiest_access[
      poorest_access,
      on = group_by,
      poorest_avg_access := i.avg_access
    ]

    palma[, palma_ratio := avg_access / poorest_avg_access]
    palma[, c("avg_access", "poorest_avg_access") := NULL]
  }

  data.table::setkeyv(palma, NULL)

  if (exists("original_class")) {
    class(palma) <- original_class
  }

  return(palma[])
}

fill_groups <- function(wealthiest_access, data, group_by) {
  # only the group combinations present in the data, not all crossings of the
  # values of each group_by column

  possible_combinations <- unique(data[, ..group_by])

  if (nrow(possible_combinations) > nrow(wealthiest_access)) {
    wealthiest_access <- possible_combinations[
      wealthiest_access,
      on = group_by,
      avg_access := i.avg_access
    ]
  }

  return(wealthiest_access[])
}
